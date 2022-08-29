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

local testfile_pattern = '^%s%s%s%s(.*_test.go):(%d+): '
local testlog_pattern = '^%s%s%s%s%s%s%s%s'
local error_pattern = { 'error' }

--- Removes `go test` specific prefixes
--- For removing newlines / tabs / whitespaces to beautify diagnostic,
--- vim.diagnostic.config(virtual_text.format) should be used
---@param output string?
---@return string?
local function sanitize_output(output)
  if not output then
    return nil
  end
  output = output:gsub(testfile_pattern, ''):gsub(testlog_pattern, '')
  return output
end

local function highlight_output(output)
  if not output then
    return output
  end
  if string.find(output, 'FAIL') then
    output = output:gsub('^', '[31m'):gsub('$', '[0m')
  elseif string.find(output, 'PASS') then
    output = output:gsub('^', '[32m'):gsub('$', '[0m')
  elseif string.find(output, 'SKIP') then
    output = output:gsub('^', '[33m'):gsub('$', '[0m')
  end
  return output
end

-- replace whitespace with underscores and remove surrounding quotes
local function transform_test_name(name)
  return name:gsub('[%s]', '_'):gsub('^"(.*)"$', '%1')
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

---@return string
local function get_build_tags()
  local line = get_buf_line(0)
  local tag_format
  for _, item in ipairs({ '// +build ', '//go:build ' }) do
    if vim.startswith(line, item) then
      tag_format = item
    end
  end
  if not tag_format then
    return ''
  end
  local tags = vim.split(line:gsub(tag_format, ''), ' ')
  if #tags < 1 then
    return ''
  end
  return fmt('-tags=%s', table.concat(tags, ','))
end

local function get_go_package_name(_)
  local line = get_buf_line(0)
  return vim.startswith('package', line) and vim.split(line, ' ')[2] or ''
end

--- gets the root directory of the go project
---@param start_file string
---@return string?
local function get_go_root(start_file)
  return lib.files.match_root_pattern('go.mod')(start_file)
end

--- gets the go module name
---@param go_root string
---@return string?
local function get_go_module_name(go_root)
  local gomod_file = go_root .. '/go.mod'
  local gomod_success, gomodule = pcall(lib.files.read_lines, gomod_file)
  if not gomod_success then
    logger.error("neotest-go: couldn't read go.mod file: " .. gomodule)
    return
  end
  local line = gomodule[1]
  local module = line:match('module (.+)')
  return module
end

local function get_experimental_opts()
  return {
    test_table = false,
  }
end

local get_args = function()
  return {}
end

--- Converts from a given go package and the "/" seperated testname to a
--- format "package::test::subtest".
--- Returns the test in this format as well as the testname of the parent test (if present)
---@param package string
---@param test string
---@return string, string?
local function normalize_test_name(package, test)
  -- sub-tests are structured as 'TestMainTest/subtest_clause'
  local parts = vim.split(test, '/')
  local is_subtest = #parts > 1
  local parenttest = is_subtest and (package .. '::' .. parts[1]) or nil
  return package .. '::' .. table.concat(parts, '::'), parenttest
end

--- Converts from a given neotest id and go_root / go_module to format
--- "package::test::subtest"
---@param id string
---@param go_root string
---@param go_module string
---@return string
local function normalize_id(id, go_root, go_module)
  local normalized_id, _ = id:gsub(go_root, go_module):gsub('/%w*_test.go', '')
  return normalized_id
end

--- Extracts the file name from a neotest id
---@param id string
---@return string
local function get_filename_from_id(id)
  local filename = string.match(id, '/(%w*_test.go)::')
  return filename
end

--- Extracts testfile and linenumber of go test output in format
--- "    main_test.go:12: Some error message\n"
---@param line string
---@return string?, number?
local function get_test_file_info(line)
  if line then
    local file, linenumber = string.match(line, testfile_pattern)
    return file, tonumber(linenumber)
  end
  return nil, nil
end

--- Checks if in the given lines contains an error pattern
---@param lines table
---@return boolean
local function is_error(lines)
  for _, line in ipairs(lines) do
    line = line:lower()
    for _, pattern in ipairs(error_pattern) do
      if line:match(pattern:lower()) then
        return true
      end
    end
  end
  return false
end

--- Checks if in the given line contains the testlog_pattern
---@param line string
---@return boolean
local function is_test_logoutput(line)
  return line and line:match(testlog_pattern) ~= nil
end

--- Converts from test (as created by marshal_gotest_output) to error (as needed by neotest)
---@param test table
---@param file_name string
---@return table?
local function get_errors_from_test(test, file_name)
  if not test.file_output[file_name] then
    return nil
  end
  local errors = {}
  for line, output in pairs(test.file_output[file_name]) do
    if is_error(output) then
      table.insert(errors, { line = line - 1, message = table.concat(output, '') })
    end
  end
  return errors
end

---Convert the json output from `gotest` to an intermediate format more similar to
---neogit.Result. Collect the progress of each test into a subtable and add a field for
---the final result
---@param lines string[]
---@return table, table
local function marshal_gotest_output(lines)
  local tests = {}
  local log = {}
  local testfile, linenumber
  for _, line in ipairs(lines) do
    if line ~= '' then
      local ok, parsed = pcall(vim.json.decode, line, { luanil = { object = true } })
      if not ok then
        log = vim.tbl_map(function(l)
          return highlight_output(l)
        end, lines)
        return tests, log
      end
      local output = highlight_output(parsed.Output)
      if output then
        table.insert(log, output)
      else
        testfile, linenumber = nil, nil
      end
      local action, package, test = parsed.Action, parsed.Package, parsed.Test
      if test then
        local status = test_statuses[action]

        local testname, parenttestname = normalize_test_name(package, test)
        if not tests[testname] then
          tests[testname] = {
            output = {},
            progress = {},
            file_output = {},
          }
        end

        -- if a new file and line number is present in the current line, use this info from now on
        -- begin collection log data with everything after the file:linenumber
        local new_test_file, new_line_number = get_test_file_info(parsed.Output)
        if new_test_file and new_line_number then
          testfile = new_test_file
          linenumber = new_line_number
          if not tests[testname].file_output[testfile] then
            tests[testname].file_output[testfile] = {}
          end

          -- In our first error line we don't want empty lines (testify logs start with empty line (\n))
          local sanitized_output = sanitize_output(parsed.Output)
          if sanitized_output and not sanitized_output:match('^%s*$') then
            tests[testname].file_output[testfile][linenumber] = {
              sanitize_output(parsed.Output),
            }
          else
            tests[testname].file_output[testfile][linenumber] = {}
          end
        end

        -- if we are in the context of a file, collect the logged data
        if testfile and linenumber and is_test_logoutput(parsed.Output) then
          table.insert(
            tests[testname].file_output[testfile][linenumber],
            sanitize_output(parsed.Output)
          )
        end

        table.insert(tests[testname].progress, action)
        if status then
          tests[testname].status = status
        end
        if output then
          table.insert(tests[testname].output, output)
          if parenttestname then
            table.insert(tests[parenttestname].output, output)
          end
        end
      end
    end
  end
  return tests, log
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

---@param position neotest.Position The position to return an ID for
---@param namespaces neotest.Position[] Any namespaces the position is within
local function generate_position_id(position, namespaces)
  local prefix = {}
  for _, namespace in ipairs(namespaces) do
    if namespace.type ~= 'file' then
      table.insert(prefix, namespace.name)
    end
  end
  local name = transform_test_name(position.name)
  return table.concat(vim.tbl_flatten({ position.path, prefix, name }), '::')
end

---@async
---@return neotest.Tree| nil
function adapter.discover_positions(path)
  local query = [[
    ((function_declaration
      name: (identifier) @test.name)
      (#match? @test.name "^(Test|Example)"))
      @test.definition

    (method_declaration
      name: (field_identifier) @test.name
      (#match? @test.name "^(Test|Example)")) @test.definition

    (call_expression
      function: (selector_expression
        field: (field_identifier) @test.method)
        (#match? @test.method "^Run$")
      arguments: (argument_list . (interpreted_string_literal) @test.name))
      @test.definition
  ]]

  if get_experimental_opts().test_table then
    query = query
      .. [[

    (block
      (short_var_declaration
        left: (expression_list
          (identifier) @test.cases)
        right: (expression_list
          (composite_literal
            (literal_value
              (literal_element
                (literal_value
                  (keyed_element
                    (literal_element
                      (identifier) @test.field.name)
                    (literal_element
                      (interpreted_string_literal) @test.name)))) @test.definition))))
      (for_statement
        (range_clause
          left: (expression_list
            (identifier) @test.case)
          right: (identifier) @test.cases1
            (#eq? @test.cases @test.cases1))
        body: (block
          (call_expression
            function: (selector_expression
              field: (field_identifier) @test.method)
              (#match? @test.method "^Run$")
            arguments: (argument_list
              (selector_expression
                operand: (identifier) @test.case1
                (#eq? @test.case @test.case1)
                field: (field_identifier) @test.field.name1
                (#eq? @test.field.name @test.field.name1)))))))
    ]]
  end

  return lib.treesitter.parse_positions(path, query, {
    require_namespaces = false,
    nested_tests = true,
    position_id = generate_position_id,
  })
end

---@param tree neotest.Tree
---@param name string
---@return string
local function get_prefix(tree, name)
  local parent_tree = tree:parent()
  if not parent_tree or parent_tree:data().type == 'file' then
    return name
  end
  local parent_name = parent_tree:data().name
  return parent_name .. '/' .. name
end

---@async
---@param args neotest.RunArgs
---@return neotest.RunSpec
function adapter.build_spec(args)
  local results_path = async.fn.tempname()
  local position = args.tree:data()
  local dir = position.path
  -- The path for the position is not a directory, ensure the directory variable refers to one
  if fn.isdirectory(position.path) ~= 1 then
    dir = fn.fnamemodify(position.path, ':h')
  end
  local package = get_go_package_name(position.path)

  local cmd_args = ({
    dir = { dir .. '/...' },
    -- file is the same as dir because running a single test file
    -- fails if it has external dependencies
    file = { dir .. '/...' },
    namespace = { package },
    test = { '-run', get_prefix(args.tree, position.name) .. '\\$', dir },
  })[position.type]

  local command = vim.tbl_flatten({
    'go',
    'test',
    '-v',
    '-json',
    get_build_tags(),
    vim.list_extend(get_args(), args.extra_args or {}),
    unpack(cmd_args),
  })

  return {
    command = table.concat(command, ' '),
    context = {
      results_path = results_path,
      file = position.path,
    },
  }
end

---@async
---@param spec neotest.RunSpec
---@param result neotest.StrategyResult
---@param tree neotest.Tree
---@return table<string, neotest.Result[]>
function adapter.results(spec, result, tree)
  local go_root = get_go_root(spec.context.file)
  if not go_root then
    return {}
  end
  local go_module = get_go_module_name(go_root)
  if not go_module then
    return {}
  end

  local success, lines = pcall(lib.files.read_lines, result.output)
  if not success then
    logger.error('neotest-go: could not read output: ' .. lines)
    return {}
  end

  local tests, log = marshal_gotest_output(lines)
  local results = {}
  local no_results = vim.tbl_isempty(tests)
  local empty_result_fname
  if no_results then
    empty_result_fname = async.fn.tempname()
    fn.writefile(log, empty_result_fname)
  end
  for _, node in tree:iter_nodes() do
    local value = node:data()
    if no_results then
      results[value.id] = {
        status = test_statuses.fail,
        output = empty_result_fname,
      }
    else
      local normalized_id = normalize_id(value.id, go_root, go_module)
      local test_result = tests[normalized_id]
      if test_result then
        local fname = async.fn.tempname()
        fn.writefile(test_result.output, fname)
        results[value.id] = {
          status = test_result.status,
          short = table.concat(test_result.output, ''),
          output = fname,
        }
        local errors = get_errors_from_test(test_result, get_filename_from_id(value.id))
        if errors then
          results[value.id].errors = errors
        end
      end
    end
  end
  return results
end

local is_callable = function(obj)
  return type(obj) == 'function' or (type(obj) == 'table' and obj.__call)
end

setmetatable(adapter, {
  __call = function(_, opts)
    if is_callable(opts.experimental) then
      get_experimental_opts = opts.experimental
    elseif opts.experimental then
      get_experimental_opts = function()
        return opts.experimental
      end
    end

    if is_callable(opts.args) then
      get_args = opts.args
    elseif opts.args then
      get_args = function()
        return opts.args
      end
    end
    return adapter
  end,
})

return adapter
