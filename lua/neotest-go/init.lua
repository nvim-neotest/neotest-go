local async = require('neotest.async')
local Path = require('plenary.path')
local lib = require('neotest.lib')

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
      name: (package_identifier) @namespace.name)
      @namespace.definition
  ]]
  return lib.treesitter.parse_positions(path, query, {
    require_namespaces = true,
  })
end

---@async
---@param args neotest.RunArgs
---@return neotest.RunSpec
function adapter.build_spec(args)
  local results_path = async.fn.tempname()
  local position = args.tree:data()
  local dir = vim.fn.fnamemodify(position.path, ":h")

  print("position: " .. vim.inspect(position))
  local cmd_args = ({
    dir = { './...' },
    file = { dir, '/...' },
    namespace = { './...' }, -- TODO: get package name
    test = { '-run', position.name.."$", dir },
  })[position.type]
  local command = { 'go', 'test', '-json', unpack(cmd_args) }
  print("command: " .. vim.inspect(command))

  return {
    command = command,
    context = {
      results_path = results_path,
      file = position.path,
    },
  }
end

local test_statuses = {
  run = 'skipped', -- the test has started running,  TODO: need a status for this
  pause = 'skipped', -- the test has been paused,   TODO: need a status for this
  cont = 'skipped', -- the test has continued running,  TODO: need a status for this
  pass = 'passed', -- the test passed
  bench = 'skipped', -- the benchmark printed log output but did not fail
  fail = 'failed', -- the test or benchmark failed
  output = 'failed', -- the test printed output
  skip = 'failed', -- the test was skipped or the package contained no tests
}

---@async
---@param _ neotest.RunSpec
---@param result neotest.StrategyResult
---@return neotest.Result[]
function adapter.results(_, result)
  local success, data = pcall(lib.files.read, result.output)
  if not success then
    data = '{}'
  end
  local lines = vim.split(data, '\r\n')
  local results = {}
  for _, line in ipairs(lines) do
    if line ~= '' then
      local parsed = vim.json.decode(line, { luanil = { object = true } })
      local short = parsed.Output and parsed.Output:gsub('\n', ''):gsub('\t', '') or ''
      table.insert(results, {
        status = test_statuses[parsed.Action],
        short = short,
        output = result.output,
      })
    end
  end
  print("results: " .. vim.inspect(results))
  return results
end

setmetatable(adapter, {
  __call = function()
    return adapter
  end,
})

return adapter
