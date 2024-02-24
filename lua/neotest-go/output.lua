local M = {}

local color = require("neotest-go.color")
local patterns = require("neotest-go.patterns")
local utils = require("neotest-go.utils")
local test_statuses = require("neotest-go.test_status")

--- Removes `go test` specific prefixes
--- For removing newlines / tabs / whitespaces to beautify diagnostic,
--- vim.diagnostic.config(virtual_text.format) should be used
---@param output string?
---@return string?
local function sanitize_output(output)
  if not output then
    return nil
  end
  output = output:gsub(patterns.testfile, ""):gsub(patterns.testlog, "")
  return output
end

---Convert the json output from `gotest` to an intermediate format more similar to
---neogit.Result. Collect the progress of each test into a subtable and add a field for
---the final result
---@param lines string[]
---@return table, table
function M.marshal_gotest_output(lines)
  local tests = {}
  local log = {}
  local testfile, linenumber
  for _, line in ipairs(lines) do
    if line ~= "" and line:sub(1, 1) == "{" then
      local ok, parsed = pcall(vim.json.decode, line, { luanil = { object = true } })
      if not ok then
        log = vim.tbl_map(function(l)
          return color.highlight_output(l)
        end, lines)
        return tests, log
      end
      local output = color.highlight_output(parsed.Output)
      if output then
        table.insert(log, output)
      else
        testfile, linenumber = nil, nil
      end
      local action, package, test = parsed.Action, parsed.Package, parsed.Test
      if test then
        local status = test_statuses[action]

        local testname, parenttestname = utils.normalize_test_name(package, test)
        if not tests[testname] then
          tests[testname] = {
            output = {},
            progress = {},
            file_output = {},
          }
        end

        -- if a new file and line number is present in the current line, use this info from now on
        -- begin collection log data with everything after the file:linenumber
        local new_test_file, new_line_number = utils.get_test_file_info(parsed.Output)
        testfile, linenumber = new_test_file, new_line_number
        if new_test_file and new_line_number then
          if not tests[testname].file_output[testfile] then
            tests[testname].file_output[testfile] = {}
          end

          -- In our first error line we don't want empty lines (testify logs start with empty line (\n))
          local sanitized_output = sanitize_output(parsed.Output)
          if sanitized_output and not sanitized_output:match("^%s*$") then
            tests[testname].file_output[testfile][linenumber] = {
              sanitize_output(parsed.Output),
            }
          else
            tests[testname].file_output[testfile][linenumber] = {}
          end
        end

        -- if we are in the context of a file, collect the logged data
        if testfile and linenumber and utils.is_test_logoutput(parsed.Output) then
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

return M
