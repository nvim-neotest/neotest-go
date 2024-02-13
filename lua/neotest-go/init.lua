local fn = vim.fn
local Path = require("plenary.path")
local lib = require("neotest.lib")
local logger = require("neotest.logging")
local async = require("neotest.async")
local utils = require("neotest-go.utils")
local output = require("neotest-go.output")
local test_statuses = require("neotest-go.test_status")

local function get_experimental_opts()
  return {
    test_table = false,
  }
end

local get_args = function()
  return {}
end

local recursive_run = function()
  return false
end

---@type neotest.Adapter
local adapter = { name = "neotest-go" }

adapter.root = lib.files.match_root_pattern("go.mod", "go.sum")

function adapter.is_test_file(file_path)
  if not vim.endswith(file_path, ".go") then
    return false
  end
  local elems = vim.split(file_path, Path.path.sep)
  local file_name = elems[#elems]
  local is_test = vim.endswith(file_name, "_test.go")
  return is_test
end

---@param position neotest.Position The position to return an ID for
---@param namespaces neotest.Position[] Any namespaces the position is within
function adapter._generate_position_id(position, namespaces)
  local prefix = {}
  for _, namespace in ipairs(namespaces) do
    if namespace.type ~= "file" then
      table.insert(prefix, namespace.name)
    end
  end
  local name = utils.transform_test_name(position.name)
  return table.concat(vim.tbl_flatten({ position.path, prefix, name }), "::")
end

---@async
---@return neotest.Tree| nil
function adapter.discover_positions(path)
  local query = [[
    ;;query
    ((function_declaration
      name: (identifier) @test.name)
      (#match? @test.name "^(Test|Example)"))
      @test.definition

    (method_declaration
      name: (field_identifier) @test.name
      (#match? @test.name "^(Test|Example)")) @test.definition

    (call_expression
      function: (selector_expression
        field: (field_identifier) @test.method)
        (#match? @test.method "^Run$")
      arguments: (argument_list . (interpreted_string_literal) @test.name))
      @test.definition
  ]]

  if get_experimental_opts().test_table then
    query = query
      .. [[
;; query for list table tests
    (block
      (short_var_declaration
        left: (expression_list
          (identifier) @test.cases)
        right: (expression_list
          (composite_literal
            (literal_value
              (literal_element
                (literal_value
                  (keyed_element
                    (literal_element
                      (identifier) @test.field.name)
                    (literal_element
                      (interpreted_string_literal) @test.name)))) @test.definition))))
      (for_statement
        (range_clause
          left: (expression_list
            (identifier) @test.case)
          right: (identifier) @test.cases1
            (#eq? @test.cases @test.cases1))
        body: (block
         (expression_statement
          (call_expression
            function: (selector_expression
              field: (field_identifier) @test.method)
              (#match? @test.method "^Run$")
            arguments: (argument_list
              (selector_expression
                operand: (identifier) @test.case1
                (#eq? @test.case @test.case1)
                field: (field_identifier) @test.field.name1
                (#eq? @test.field.name @test.field.name1))))))))

;; query for map table tests 
	(block
      (short_var_declaration
        left: (expression_list
          (identifier) @test.cases)
        right: (expression_list
          (composite_literal
            (literal_value
              (keyed_element
            	(literal_element
                  (interpreted_string_literal)  @test.name)
                (literal_element
                  (literal_value)  @test.definition))))))
	  (for_statement
       (range_clause
          left: (expression_list
            ((identifier) @test.key.name)
            ((identifier) @test.case))
          right: (identifier) @test.cases1
            (#eq? @test.cases @test.cases1))
	      body: (block
           (expression_statement
            (call_expression
              function: (selector_expression
                field: (field_identifier) @test.method)
                (#match? @test.method "^Run$")
                arguments: (argument_list
                ((identifier) @test.key.name1
                (#eq? @test.key.name @test.key.name1))))))))
    ]]
  end

  return lib.treesitter.parse_positions(path, query, {
    require_namespaces = false,
    nested_tests = true,
    position_id = "require('neotest-go')._generate_position_id",
  })
end

---@async
---@param args neotest.RunArgs
---@return neotest.RunSpec
function adapter.build_spec(args)
  local results_path = async.fn.tempname()
  local position = args.tree:data()
  local dir = "./"
  if recursive_run() then
    dir = "./..."
  end
  local location = position.path
  if fn.isdirectory(position.path) ~= 1 then
    location = fn.fnamemodify(position.path, ":h")
  end
  local command = vim.tbl_flatten({
    "cd",
    location,
    "&&",
    "go",
    "test",
    "-v",
    "-json",
    utils.get_build_tags(),
    vim.list_extend(get_args(), args.extra_args or {}),
    dir,
  })
  return {
    command = table.concat(command, " "),
    context = {
      results_path = results_path,
      file = position.path,
    },
  }
end

---@async
---@param spec neotest.RunSpec
---@param result neotest.StrategyResult
---@param tree neotest.Tree
---@return table<string, neotest.Result[]>
function adapter.results(spec, result, tree)
  local go_root = utils.get_go_root(spec.context.file)
  if not go_root then
    return {}
  end
  local go_module = utils.get_go_module_name(go_root)
  if not go_module then
    return {}
  end

  local success, lines = pcall(lib.files.read_lines, result.output)
  if not success then
    logger.error("neotest-go: could not read output: " .. lines)
    return {}
  end
  return adapter.prepare_results(tree, lines, go_root, go_module)
end

---@param tree neotest.Tree
---@param lines string[]
---@param go_root string
---@param go_module string
---@return table<string, neotest.Result[]>
function adapter.prepare_results(tree, lines, go_root, go_module)
  local tests, log = output.marshal_gotest_output(lines)
  local results = {}
  local no_results = vim.tbl_isempty(tests)
  local empty_result_fname
  empty_result_fname = async.fn.tempname()
  fn.writefile(log, empty_result_fname)
  for _, node in tree:iter_nodes() do
    local node_data = node:data()
    if no_results then
      results[node_data.id] = {
        status = test_statuses.fail,
        output = empty_result_fname,
      }
      break
    end

    if node_data.type ~= "file" then
      local file_path = node_data.path
      local file_id = utils.get_filename_from_id(node_data.id)
      local normalized_node_test_id = utils.normalize_id(node_data.id, go_root, go_module)
      local node_test_result = tests[normalized_node_test_id]

      if node_test_result then
        if not results[file_path] then
          results[file_path] = {
            status = test_statuses.pass,
            output = empty_result_fname,
          }
        end

        local node_fname = async.fn.tempname()
        fn.writefile(node_test_result.output, node_fname)
        results[node_data.id] = {
          status = node_test_result.status,
          short = table.concat(node_test_result.output, ""),
          output = node_fname,
          errors = {},
        }

        for _, test_result in pairs(tests) do
          if test_result.parenttestname == normalized_node_test_id then
            local test_id, _ = utils.normalize_test_name(file_path, test_result.test)
            local test_fname = async.fn.tempname()
            fn.writefile(test_result.output, test_fname)
            results[test_id] = {
              status = test_result.status,
              short = table.concat(test_result.output, ""),
              output = test_fname,
              errors = {},
            }

            local errors = utils.get_errors_from_test(test_result, file_id)
            if errors then
              for _, error in ipairs(errors) do
                table.insert(results[node_data.id].errors, error)
              end
            end

            if test_result.status == test_statuses.fail then
              results[file_path].status = test_statuses.fail
            end
          end
        end
      end
    end
  end

  return results
end

local is_callable = function(obj)
  return type(obj) == "function" or (type(obj) == "table" and obj.__call)
end

setmetatable(adapter, {
  __call = function(_, opts)
    if is_callable(opts.experimental) then
      get_experimental_opts = opts.experimental
    elseif opts.experimental then
      get_experimental_opts = function()
        return opts.experimental
      end
    end

    if is_callable(opts.args) then
      get_args = opts.args
    elseif opts.args then
      get_args = function()
        return opts.args
      end
    end

    if is_callable(opts.recursive_run) then
      recursive_run = opts.recursive_run
    elseif opts.recursive_run then
      recursive_run = function()
        return opts.recursive_run
      end
    end
    return adapter
  end,
})

return adapter
