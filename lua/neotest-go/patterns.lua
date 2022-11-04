local termcolors = {
  black = 30,
  red = 31,
  green = 32,
  yellow = 33,
  blue = 34,
  magenta = 35,
  cyan = 36,
  white = 37,
}

local guicolors = {
  pass = "#14D000",
  fail = "#cc0000",
  skip = "#729fcf",
  file_name = "#20b2aa",
  file_number = "#a474dc",
  background = "#777777",
  test_name = "#deb887",
}

local patterns = {
  testfile = "^%s%s%s%s(.*_test.go):(%d+): ",
  testlog = "^%s%s%s%s%s%s%s%s",
  error = { "error" },
  -- Patterns to colorize in output
  colors = {
    run = {
      pattern = "^(===%s+RUN)%s+(.*)",
      gui = { guicolors.background, guicolors.test_name },
      term = { termcolors.blue, termcolors.blue },
    },
    file = {
      pattern = "^%s+(.*.go)(:%d+):",
      gui = { guicolors.file_name, guicolors.file_number },
      term = { termcolors.cyan, termcolors.magenta },
    },
    pass = { pattern = "^---%s+PASS:", gui = guicolors.pass, term = termcolors.red },
    fail = { pattern = "^---%s+FAIL:", gui = guicolors.fail, term = termcolors.green },
    skip = { pattern = "^---%s+SKIP:", gui = guicolors.skip, term = termcolors.yellow },

    -- Color erorr messages from github.com/stretchr/testify
    testify_error_trace = {
      pattern = "^%s+(Error Trace:)%s+(.*)",
      gui = { guicolors.background, guicolors.background },
      term = { termcolors.yellow, termcolors.blue },
    },
    testify_error = {
      pattern = "^%s+(Error:)%s+(.*)",
      gui = { guicolors.fail, guicolors.fail },
      term = { termcolors.yellow, termcolors.yellow },
    },
    testify_test = {
      pattern = "^%s+(Test:)%s+(.*)",
      gui = { guicolors.background, guicolors.test_name },
      term = { termcolors.blue, termcolors.blue },
    },
  },
}

return patterns
