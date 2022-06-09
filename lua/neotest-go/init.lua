local async = require('neotest.async')
local Path = require('plenary.path')
local lib = require('neotest.lib')
local logger = require('neotest.logging')

local api = vim.api
local fn = vim.fn
local fmt = string.format

local test_statuses = {
  -- NOTE: Do these statuses need to be handled
  run = false, -- the test has started running
  pause = false, -- the test has been paused
  cont = false, -- the test has continued running
  bench = false, -- the benchmark printed log output but did not fail
  output = false, -- the test printed output
  --------------------------------------------------
  pass = 'passed', -- the test passed
  fail = 'failed', -- the test or benchmark failed
  skip = 'skipped', -- the test was skipped or the package contained no tests
}

--- Remove newlines from test output
---@param output string
---@return string
local function sanitize_output(output)
  if not output then
    return output
  end
  return output:gsub('\n', ''):gsub('\t', '')
end

---Get a line in a buffer, defaulting to the first if none is specified
---@param buf number
---@param nr number?
---@return string
local function get_buf_line(buf, nr)
  nr = nr or 0
  assert(buf and type(buf) == 'number', 'A buffer is required to get the first line')
  return vim.trim(api.nvim_buf_get_lines(buf, nr, nr + 1, false)[1])
end

---@return string?
local function get_build_tags()
  local line = get_buf_line(0)
  local tag_format
  for _, item in ipairs({ '// +build ', '//go:build ' }) do
    if vim.startswith(line, item) then
      tag_format = item
    end
  end
  if not tag_format then
    return
  end
  local tags = vim.split(line:gsub(tag_format, ''), ' ')
  if #tags < 1 then
    return
  end
  return fmt('-tags=%s', table.concat(tags, ','))
end

local function get_go_package_name(_)
  local line = get_buf_line(0)
  return vim.startswith('package', line) and vim.split(line, ' ')[2] or ''
end

---Convert the json output from `gotest` to an intermediate format more similar to
---neogit.Result. Collect the progress of each test into a subtable and add a field for
---the final result
---@param lines string[]
---@param output_file string
local function marshall_gotest_output(lines, output_file)
  local tests = {}
  for _, line in ipairs(lines) do
    if line ~= '' then
      local ok, parsed = pcall(vim.json.decode, line, { luanil = { object = true } })
      if not ok then
        logger.error('Failed to parse test output ', output_file)
        return {}
      end
      local output = sanitize_output(parsed.Output)
      local action, name = parsed.Action, parsed.Test
      if name then
        local status = test_statuses[action]
        -- sub-tests are structured as 'TestMainTest/subtest_clause'
        local parts = vim.split(name, '/')
        local is_subtest = #parts > 1
        local parent = is_subtest and parts[1] or nil
        tests[name] = tests[name]
          or {
            output = {},
            progress = {},
            output_file = output_file,
          }
        table.insert(tests[name].progress, action)
        if status then
          tests[name].status = status
        end
        if output then
          table.insert(tests[name].output, output)
          if parent then
            table.insert(tests[parent].output, output)
          end
        end
      else
        tests.__unnamed = tests.__unnamed or { output = {} }
        table.insert(tests.__unnamed.output, output)
      end
    end
  end
  return tests
end

---@type neotest.Adapter
local adapter = { name = 'neotest-go' }

adapter.root = lib.files.match_root_pattern('go.mod', 'go.sum')

function adapter.is_test_file(file_path)
  if not vim.endswith(file_path, '.go') then
    return false
  end
  local elems = vim.split(file_path, Path.path.sep)
  local file_name = elems[#elems]
  local is_test = vim.endswith(file_name, '_test.go')
  return is_test
end

---@async
---@return neotest.Tree| nil
function adapter.discover_positions(path)
  local query = [[
    ((function_declaration
      name: (identifier) @test.name)
      (#match? @test.name "^Test"))
      @test.definition

    (package_clause
      (package_identifier) @namespace.name)
      @namespace.definition
  ]]
  return lib.treesitter.parse_positions(path, query, {
    require_namespaces = false,
    nested_tests = true,
  })
end

---@async
---@param args neotest.RunArgs
---@return neotest.RunSpec
function adapter.build_spec(args)
  local results_path = async.fn.tempname()
  local position = args.tree:data()
  local dir = vim.fn.fnamemodify(position.path, ':h')
  local package = get_go_package_name(position.path)

  local cmd_args = ({
    dir = { dir .. '/...' },
    file = { position.path },
    namespace = { package },
    test = { '-run', position.name .. '$', dir },
  })[position.type]

  local command = { 'go', 'test', '-v', '-json', unpack(cmd_args) }
  local tags = get_build_tags()
  if tags then
    table.insert(command, 4, tags)
  end

  return {
    command = command,
    context = {
      results_path = results_path,
      file = position.path,
    },
  }
end

---@async
---@param _ neotest.RunSpec
---@param result neotest.StrategyResult
---@param tree neotest.Tree
---@return table<string, neotest.Result[]>
function adapter.results(_, result, tree)
  local success, data = pcall(lib.files.read, result.output)
  if not success then
    return {}
  end
  local lines = vim.split(data, '\r\n')
  local tests = marshall_gotest_output(lines, result.output)
  local results = {}
  local no_results = vim.tbl_isempty(tests)
  local empty_result_fname
  if no_results and tests.__unnamed then
    empty_result_fname = async.fn.tempname()
    fn.writefile(tests.__unnamed.output, empty_result_fname)
  end
  for _, value in tree:iter() do
    if no_results then
      results[value.id] = {
        status = 'skipped',
        output = empty_result_fname,
      }
    else
      local test_output = tests[value.name]
      if test_output then
        local fname = async.fn.tempname()
        fn.writefile(test_output.output, fname)
        results[value.id] = {
          status = test_output.status,
          short = table.concat(test_output.output, '\n'),
          output = fname,
        }
      end
    end
  end
  return results
end

setmetatable(adapter, {
  __call = function()
    return adapter
  end,
})

return adapter
