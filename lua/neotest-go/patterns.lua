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
  green = "#14D000",
  red = "#cc0000",
  dark_blue = "#729fcf",
  cyan = "#20b2aa",
  magenta = "#a474dc",
  grey = "#777777",
  yellow = "#deb887",
  orange = "#ff7373",
}

local patterns = {
  testfile = "^%s%s%s%s(.*_test.go):(%d+): ",
  testlog = "^%s%s%s%s%s%s%s%s",
  error = { "error" },
  -- Patterns to colorize in output
  colors = {
    pass = { pattern = "^%s*---%s+PASS:", gui = guicolors.green, term = termcolors.red },
    fail = { pattern = "^---%s+FAIL:", gui = guicolors.red, term = termcolors.green },
    skip = { pattern = "^---%s+SKIP:", gui = guicolors.dark_blue, term = termcolors.yellow },
    build = { pattern = "^===%s+BUILD", gui = guicolors.yellow, term = termcolors.yellow },
    comment = { pattern = "^#", gui = guicolors.grey, term = termcolors.blue },
    run = {
      pattern = "^(===%s+RUN)%s+(.*)",
      gui = { guicolors.grey, guicolors.yellow },
      term = { termcolors.blue, termcolors.blue },
    },
    signal = {
      pattern = "^(%[signal)%s(.*)(:.*%])",
      gui = { guicolors.grey, guicolors.dark_blue, guicolors.grey },
      term = { termcolors.blue, termcolors.red, termcolors.blue },
    },
    panic = {
      pattern = "^%s+(panic:)%s+(.*)",
      gui = { guicolors.red, guicolors.orange },
      term = { termcolors.red, termcolors.red },
    },
    panic_recovered = {
      pattern = "^(panic:)%s+(.*)%s(%[.*%])",
      gui = { guicolors.red, guicolors.orange, guicolors.dark_blue },
      term = { termcolors.red, termcolors.red, termcolors.blue },
    },
    go_routine = {
      pattern = "^(goroutine)%s(%d+)%s(%[.*])(:)",
      gui = { guicolors.grey, guicolors.magenta, guicolors.dark_blue, guicolors.grey },
      term = { termcolors.blue, termcolors.blue, termcolors.magenta, termcolors.blue },
    },
    file = {
      pattern = "^%s+(.*.go)(:%d+)",
      gui = { guicolors.cyan, guicolors.magenta },
      term = { termcolors.cyan, termcolors.magenta },
    },
    file_column = {
      pattern = "^%s*(.*.go)(:%d+)(:%d+)",
      gui = { guicolors.cyan, guicolors.magenta, guicolors.dark_blue },
      term = { termcolors.cyan, termcolors.magenta, termcolors.blue },
    },
    file_panic = {
      pattern = "^%s+(.*.go)(:%d+)%s+(%+0x%w+)",
      gui = { guicolors.cyan, guicolors.magenta, guicolors.grey },
      term = { termcolors.cyan, termcolors.magenta, termcolors.blue },
    },
    -- Color erorr messages from github.com/stretchr/testify
    testify_error_trace = {
      pattern = "^%s+(Error Trace:)%s+(.*)",
      gui = { guicolors.grey, guicolors.grey },
      term = { termcolors.yellow, termcolors.blue },
    },
    testify_error = {
      pattern = "^%s+(Error:)%s+(.*)",
      gui = { guicolors.red, guicolors.red },
      term = { termcolors.yellow, termcolors.yellow },
    },
    testify_test = {
      pattern = "^%s+(Test:)%s+(.*)",
      gui = { guicolors.grey, guicolors.yellow },
      term = { termcolors.blue, termcolors.blue },
    },
  },
}

return patterns
