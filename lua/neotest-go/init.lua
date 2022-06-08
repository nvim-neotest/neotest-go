local async = require('neotest.async')
local Path = require('plenary.path')
local lib = require('neotest.lib')
local api = vim.api

local test_statuses = {
  run = false, -- the test has started running,  TODO: need a status for this
  pause = false, -- the test has been paused,   TODO: need a status for this
  cont = false, -- the test has continued running,  TODO: need a status for this
  bench = false, -- the benchmark printed log output but did not fail
  output = false, -- the test printed output
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

local function get_go_package_name(buf)
  buf = buf or 0
  local package_line = vim.trim(api.nvim_buf_get_lines(buf, 0, 1, false)[1])
  local package = vim.startswith("package") and vim.split(package_line, " ")[2] or ""
  return package
end

--- Convert the json output from `gotest` to an intermediate format more similar to
--- neogit.Result. Collect the progress of each test into a subtable and add a field for
--- the final result
---@param lines string[]
---@param output_file string
local function marshall_gotest_output(lines, output_file)
  local tests = {}
  for _, line in ipairs(lines) do
    if line ~= '' then
      local ok, parsed = pcall(vim.json.decode, line, { luanil = { object = true } })
      if not ok then
        vim.schedule(function() -- FIXME: Report global errors correctly
          vim.notify('Failed to run go tests: ' .. parsed)
        end)
      else
        local output = sanitize_output(parsed.Output)
        local action, name = parsed.Action, parsed.Test
        if name then
          local status = test_statuses[action]
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
          end
        end
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
    dir = { './...' },
    file = { dir .. '/...' },
    namespace = { package },
    test = { '-run', position.name .. '$', dir },
  })[position.type]
  local command = { 'go', 'test', '-json', unpack(cmd_args) }

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
  for _, value in tree:iter() do
    local test_output = tests[value.name]
    if test_output then
      results[value.id] = {
        status = test_output.status,
        short = table.concat(test_output.output, '\n'),
        output = test_output.output_file,
      }
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
