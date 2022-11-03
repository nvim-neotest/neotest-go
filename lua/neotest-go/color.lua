local M = {}

-- Highlight some parts of the test output
function M.highlight_output(output)
  if not output then
    return output
  end
  if string.find(output, "FAIL") then
    output = output:gsub("^", "[31m"):gsub("$", "[0m")
  elseif string.find(output, "PASS") then
    output = output:gsub("^", "[32m"):gsub("$", "[0m")
  elseif string.find(output, "SKIP") then
    output = output:gsub("^", "[33m"):gsub("$", "[0m")
  end
  return output
end

return M
