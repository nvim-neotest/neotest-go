local assert = require("luassert")
local utils = require("neotest-go.utils")

describe("normalize_id", function()
  it("normalize_id is correct", function()
    local tests_folder = vim.loop.cwd() .. "/neotest_go"
    local test_file = tests_folder .. "/cases_test.go"

    assert.equals("neotest_go", utils.normalize_id(test_file, tests_folder, "neotest_go"))
  end)
  it("normalize id supports dots in file name", function()
    local tests_folder = vim.loop.cwd() .. "/neotest_go"
    local test_file = tests_folder .. "/suite.something_test.go"
    assert.equals("neotest_go", utils.normalize_id(test_file, tests_folder, "neotest_go"))
  end)
  it("id_to_suite_test_name", function()
    local res = utils.id_to_suite_test_name(
      "/path/to/something_test.go::SomethingTestSuite::TestSomething::some_case"
    )
    assert.equals("TestSomethingTestSuite/TestSomething/some_case", res)
  end)
  it("suite_test_name_to_test_name", function()
    local res = utils.suite_test_name_to_test_name("TestSomethingTestSuite/TestSomething/some_case")
    assert.equals("SomethingTestSuite/TestSomething/some_case", res)
  end)
end)
