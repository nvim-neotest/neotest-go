local M = {}

M.benchmark_regex = '[^Benchmark$|^Benchmark\\P{Ll}.*]'

---@param strategy string
---@param args table
---@return table | nil
M.get_strategy_config = function(strategy, args)
  local config = {
    dap = function()
      return {
        type = 'go',
        name = 'Neotest Debugger',
        request = 'launch',
        mode = 'test',
        program = './${relativeFileDirname}',
        args = args,
      }
    end,
  }
  if config[strategy] then
    return config[strategy]()
  end

  return nil
end

--@param test_func_name string
--@return boolean
M.is_benchmark_test = function(test_func_name)
  local rg = vim.regex(M.benchmark_regex)

  local match  = rg:match_str(test_func_name)
  if match == 0 or match == nil then
    return false
  end
  return true
end

---@param func_name string
---@return table
M.get_test_function_debug_args = function(func_name)
  if M.is_benchmark_test(func_name) then
    return {
      '-test.bench',
      '^' .. func_name .. '$',
      '-test.run',
      'a^',
    }
  end

  -- TODO: add testify support
  -- see vscode-go implementation at https://github.com/golang/vscode-go/blob/8dfd39349da7a523b4ed0f781c9d10c753be76bf/src/testUtils.ts#L191-L191
  local args = {
    '-test.run',
    '^' .. func_name .. '$',
  }

  return args
end

return M
