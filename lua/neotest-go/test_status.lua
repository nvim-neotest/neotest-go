local test_statuses = {
  -- NOTE: Do these statuses need to be handled
  run = false, -- the test has started running
  pause = false, -- the test has been paused
  cont = false, -- the test has continued running
  bench = false, -- the benchmark printed log output but did not fail
  output = false, -- the test printed output
  --------------------------------------------------
  pass = "passed", -- the test passed
  fail = "failed", -- the test or benchmark failed
  skip = "skipped", -- the test was skipped or the package contained no tests
}

return test_statuses
