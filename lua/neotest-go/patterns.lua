local patterns = {
  testfile = "^%s%s%s%s(.*_test.go):(%d+): ",
  testlog = "^%s%s%s%s%s%s%s%s",
  error = { "error" },
  -- Patterns to colorize in output
  colors = {
    run = { pattern = "(===%s+RUN)%s+(.*)", gui = { "#777777", "#deb887" }, term = { 34, 34 } },
    file = { pattern = "^%s+(.*.go):(%d+):", gui = { "#20b2aa", "#a474dc" }, term = { 36, 35 } },
    pass = { pattern = "^---%s+PASS:", gui = "#14D000", term = 31 },
    fail = { pattern = "^---%s+FAIL:", gui = "#cc0000", term = 32 },
    skip = { pattern = "^---%s+SKIP:", gui = "#729fcf", term = 33 },
  },
}

return patterns
