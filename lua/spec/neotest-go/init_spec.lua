local nio = require("nio")
local async = nio.tests
local plugin = require("neotest-go")
local assert = require("luassert")
local say = require("say")
local test_statuses = require("neotest-go.test_status")

local function create_tree(positions)
  return Tree.from_list(positions, function(pos)
    return pos.id
  end)
end

local function has_property(state, arguments)
  local property = arguments[1]
  local table = arguments[2]
  for key, value in pairs(table) do
    if key == property then
      return true
    end
  end
  return false
end

say:set_namespace("en")
say:set("assertion.has_property.positive", "Expected property %s in:\n%s")
say:set("assertion.has_property.negative", "Expected property %s to not be in:\n%s")
assert:register(
  "assertion",
  "has_property",
  has_property,
  "assertion.has_property.positive",
  "assertion.has_property.negative"
)

-- configure plugin with tested options
plugin({
  experimental = {
    test_table = true,
  },
  args = { "-count=1", "-timeout=60s" },
})

describe("is_test_file", function()
  async.it("matches Go files", function()
    assert.equals(true, plugin.is_test_file("foo_test.go"))
  end)
end)

describe("discover_positions", function()
  async.it("discovers positions in unit tests in many_table_test.go", function()
    local path = vim.loop.cwd() .. "/neotest_go/many_table_test.go"
    local positions = plugin.discover_positions(path):to_list()

    local expected_positions = {
      {
        id = vim.loop.cwd() .. "/neotest_go/many_table_test.go",
        name = "many_table_test.go",
        path = vim.loop.cwd() .. "/neotest_go/many_table_test.go",
        range = { 0, 0, 32, 0 },
        type = "file",
      },
      {
        {
          id = vim.loop.cwd() .. "/neotest_go/many_table_test.go::TestSomeTest",
          name = "TestSomeTest",
          path = vim.loop.cwd() .. "/neotest_go/many_table_test.go",
          range = { 8, 0, 31, 1 },
          type = "test",
        },
        {
          {
            id = vim.loop.cwd() .. "/neotest_go/many_table_test.go::TestSomeTest::AccessDenied1",
            name = '"AccessDenied1"',
            path = vim.loop.cwd() .. "/neotest_go/many_table_test.go",
            range = { 16, 2, 16, 118 },
            type = "test",
          },
        },
        {
          {
            id = vim.loop.cwd() .. "/neotest_go/many_table_test.go::TestSomeTest::AccessDenied2",
            name = '"AccessDenied2"',
            path = vim.loop.cwd() .. "/neotest_go/many_table_test.go",
            range = { 17, 2, 17, 118 },
            type = "test",
          },
        },
        {
          {
            id = vim.loop.cwd() .. "/neotest_go/many_table_test.go::TestSomeTest::AccessDenied3",
            name = '"AccessDenied3"',
            path = vim.loop.cwd() .. "/neotest_go/many_table_test.go",
            range = { 18, 2, 18, 118 },
            type = "test",
          },
        },
        {
          {
            id = vim.loop.cwd() .. "/neotest_go/many_table_test.go::TestSomeTest::AccessDenied4",
            name = '"AccessDenied4"',
            path = vim.loop.cwd() .. "/neotest_go/many_table_test.go",
            range = { 19, 2, 19, 118 },
            type = "test",
          },
        },
        {
          {
            id = vim.loop.cwd() .. "/neotest_go/many_table_test.go::TestSomeTest::AccessDenied5",
            name = '"AccessDenied5"',
            path = vim.loop.cwd() .. "/neotest_go/many_table_test.go",
            range = { 20, 2, 20, 118 },
            type = "test",
          },
        },
        {
          {
            id = vim.loop.cwd() .. "/neotest_go/many_table_test.go::TestSomeTest::AccessDenied6",
            name = '"AccessDenied6"',
            path = vim.loop.cwd() .. "/neotest_go/many_table_test.go",
            range = { 21, 2, 21, 118 },
            type = "test",
          },
        },
      },
    }
    assert.are.same(positions, expected_positions)
  end)
  async.it("discovers positions in unit tests in cases_test.go", function()
    local path = vim.loop.cwd() .. "/neotest_go/cases_test.go"
    local positions = plugin.discover_positions(path):to_list()
    local expected_positions = {
      {
        id = vim.loop.cwd() .. "/neotest_go/cases_test.go",
        name = "cases_test.go",
        path = vim.loop.cwd() .. "/neotest_go/cases_test.go",
        range = { 0, 0, 49, 0 },
        type = "file",
      },
      {
        {
          id = vim.loop.cwd() .. "/neotest_go/cases_test.go::TestSubtract",
          name = "TestSubtract",
          path = vim.loop.cwd() .. "/neotest_go/cases_test.go",
          range = { 8, 0, 33, 1 },
          type = "test",
        },
        {
          {
            id = vim.loop.cwd() .. "/neotest_go/cases_test.go::TestSubtract::test_one",
            name = '"test one"',
            path = vim.loop.cwd() .. "/neotest_go/cases_test.go",
            range = { 15, 2, 20, 3 },
            type = "test",
          },
        },
        {
          {
            id = vim.loop.cwd() .. "/neotest_go/cases_test.go::TestSubtract::test_two",
            name = '"test two"',
            path = vim.loop.cwd() .. "/neotest_go/cases_test.go",
            range = { 21, 2, 26, 3 },
            type = "test",
          },
        },
      },
      {
        {
          id = vim.loop.cwd() .. "/neotest_go/cases_test.go::TestAdd",
          name = "TestAdd",
          path = vim.loop.cwd() .. "/neotest_go/cases_test.go",
          range = { 35, 0, 48, 1 },
          type = "test",
        },
        {
          {
            id = vim.loop.cwd() .. "/neotest_go/cases_test.go::TestAdd::test_one",
            name = '"test one"',
            path = vim.loop.cwd() .. "/neotest_go/cases_test.go",
            range = { 36, 1, 38, 3 },
            type = "test",
          },
        },
        {
          {
            id = vim.loop.cwd() .. "/neotest_go/cases_test.go::TestAdd::test_two",
            name = '"test two"',
            path = vim.loop.cwd() .. "/neotest_go/cases_test.go",
            range = { 40, 1, 42, 3 },
            type = "test",
          },
        },
      },
    }

    assert.are.same(positions, expected_positions)
  end)
  async.it("discovers positions in unit tests in map_table_test.go", function()
    local path = vim.loop.cwd() .. "/neotest_go/map_table_test.go"
    local positions = plugin.discover_positions(path):to_list()
    local expected_positions = {
      {
        id = vim.loop.cwd() .. "/neotest_go/map_table_test.go",
        name = "map_table_test.go",
        path = vim.loop.cwd() .. "/neotest_go/map_table_test.go",
        range = { 0, 0, 40, 0 },
        type = "file",
      },
      {
        {
          id = vim.loop.cwd() .. "/neotest_go/map_table_test.go::TestSplit",
          name = "TestSplit",
          path = vim.loop.cwd() .. "/neotest_go/map_table_test.go",
          range = { 8, 0, 28, 1 },
          type = "test",
        },
        {
          {
            id = vim.loop.cwd() .. "/neotest_go/map_table_test.go::TestSplit::simple",
            name = '"simple"',
            path = vim.loop.cwd() .. "/neotest_go/map_table_test.go",
            range = { 14, 18, 14, 75 },
            type = "test",
          },
        },
        {
          {
            id = vim.loop.cwd() .. "/neotest_go/map_table_test.go::TestSplit::wrong_sep",
            name = '"wrong sep"',
            path = vim.loop.cwd() .. "/neotest_go/map_table_test.go",
            range = { 15, 18, 15, 69 },
            type = "test",
          },
        },
        {
          {
            id = vim.loop.cwd() .. "/neotest_go/map_table_test.go::TestSplit::no_sep",
            name = '"no sep"',
            path = vim.loop.cwd() .. "/neotest_go/map_table_test.go",
            range = { 16, 18, 16, 65 },
            type = "test",
          },
        },
        {
          {
            id = vim.loop.cwd() .. "/neotest_go/map_table_test.go::TestSplit::trailing_sep",
            name = '"trailing sep"',
            path = vim.loop.cwd() .. "/neotest_go/map_table_test.go",
            range = { 17, 18, 17, 76 },
            type = "test",
          },
        },
      },
    }
    assert.are.same(positions, expected_positions)
  end)
end)

describe("prepare_results", function()
  async.it(
    "check that we have file level test result as well as all nested results in cases_test.go",
    function()
      local tests_folder = vim.loop.cwd() .. "/neotest_go"
      local test_file = tests_folder .. "/cases_test.go"
      local positions = plugin.discover_positions(test_file)

      local expected_keys = {
        test_file,
        test_file .. "::TestAdd",
        test_file .. "::TestAdd::test_one",
        test_file .. "::TestAdd::test_two",
        test_file .. "::TestSubtract",
        test_file .. "::TestSubtract::test_one",
        test_file .. "::TestSubtract::test_two",
      }
      -- we should run test from module root
      local command = {
        "cd",
        tests_folder,
        "&&",
        "go",
        "test",
        "-v",
        "-json",
        "",
        "-count=1",
        "-timeout=60s",
        "./...",
      }
      local handle = io.popen(table.concat(command, " "))
      local result = handle:read("*a")
      handle:close()

      local lines = {}
      for s in result:gmatch("[^\r\n]+") do
        table.insert(lines, s)
      end
      local processed_results = plugin.prepare_results(positions, lines, tests_folder, "neotest_go")

      for _, v in pairs(expected_keys) do
        assert.has_property(v, processed_results)
      end
    end
  )
  async.it("check that we have correct file level test result status", function()
    local tests_folder = vim.loop.cwd() .. "/neotest_go"
    local test_cases = {}
    test_cases["cases_test.go"] = { status = test_statuses.fail }
    test_cases["main_test.go"] = { status = test_statuses.pass }
    for test_name, test_result in pairs(test_cases) do
      async.it(test_name, function()
        local test_file = tests_folder .. "/" .. test_name
        local positions = plugin.discover_positions(test_file)
        -- we should run test from module root
        local command = {
          "cd",
          tests_folder,
          "&&",
          "go",
          "test",
          "-v",
          "-json",
          "",
          "-count=1",
          "-timeout=60s",
          "./...",
        }
        local handle = io.popen(table.concat(command, " "))
        local result = handle:read("*a")
        handle:close()

        local lines = {}
        for s in result:gmatch("[^\r\n]+") do
          table.insert(lines, s)
        end
        local processed_results =
          plugin.prepare_results(positions, lines, tests_folder, "neotest_go")

        assert.equals(test_result.status, processed_results[test_file].status)
      end)
    end
  end)
end)

describe("build_spec", function()
  async.it("build specification for many_table_test.go", function()
    local path = vim.loop.cwd() .. "/neotest_go/many_table_test.go"
    local tree = plugin.discover_positions(path)

    local args = { tree = tree }
    local expected_command = "cd "
      .. vim.loop.cwd()
      .. "/neotest_go && go test -v -json  -count=1 -timeout=60s ./..."
    local result = plugin.build_spec(args)
    assert.are.same(expected_command, result.command)
    assert.are.same(path, result.context.file)
  end)
end)

describe("suite", function()
  async.it("check that suite positions are discovered", function()
    local path = vim.loop.cwd() .. "/neotest_go/suite_test.go"
    local positions = plugin.discover_positions(path):to_list()
    local expected_positions = {
      {
        id = path,
        path = path,
        name = "suite_test.go",
        range = { 0, 0, 39, 0 },
        type = "file",
      },
      {
        {
          id = path .. "::ExampleTestSuite",
          name = "ExampleTestSuite",
          path = path,
          range = { 26, 0, 28, 1 },
          type = "namespace",
        },
        {
          {
            id = path .. "::ExampleTestSuite::TestExample",
            name = "TestExample",
            path = path,
            range = { 26, 0, 28, 1 },
            type = "test",
          },
        },
      },
      {
        {
          id = path .. "::ExampleTestSuite",
          name = "ExampleTestSuite",
          path = path,
          range = { 30, 0, 32, 1 },
          type = "namespace",
        },
        {
          {
            id = path .. "::ExampleTestSuite::TestExampleFailure",
            name = "TestExampleFailure",
            path = path,
            range = { 30, 0, 32, 1 },
            type = "test",
          },
        },
      },
      {
        {
          id = path .. "::TestExampleTestSuite",
          name = "TestExampleTestSuite",
          path = path,
          range = { 36, 0, 38, 1 },
          type = "test",
        },
      },
    }
    assert.are.same(expected_positions, positions)
  end)

  async.it("build spec for a single suite test", function()
    local path = vim.loop.cwd() .. "/neotest_go/suite_test.go"

    -- TestExample
    local tree = plugin.discover_positions(path):children()[1]:children()[1]
    local result = plugin.build_spec({ tree = tree })
    local expected_command = (
      "cd "
      .. vim.loop.cwd()
      .. "/neotest_go"
      .. " && "
      .. "go test -v -json  -count=1 -timeout=60s ./... -run TestExampleTestSuite/TestExample"
    )
    assert.are.same(expected_command, result.command)
  end)
end)
