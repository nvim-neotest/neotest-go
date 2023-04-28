local assert = require("luassert")
local utils = require("neotest-go.utils")

describe("normalize_id", function()
  it("normalize_id is correct", function()
    local tests_folder = vim.loop.cwd() .. "/neotest_go"
    local test_file = tests_folder .. "/cases_test.go"

    assert.equals("neotest_go", utils.normalize_id(test_file, tests_folder, "neotest_go"))
  end)
end)
