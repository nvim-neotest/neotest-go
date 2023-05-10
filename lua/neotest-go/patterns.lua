local patterns = {
  testfile = "^%s%s%s%s(.*_test.go):(%d+): ",
  testify_assert_file = ".*Error Trace:%s*(.-)(.-_test%.go):(%d+)",
  testifY_callstack_testfile = ".*at:%s*%[(.-_test%.go):(%d+)%]",
  testlog = "^%s*(%S.*)",
  error = { "error", "fail" },
}

return patterns
