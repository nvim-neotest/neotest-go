local utils = require('neotest-go.utils')

describe('utils', function()
  describe('is_benchmark_test', function()
    it('returns false on test functions', function()
      is_bench = utils.is_benchmark_test('TestExample')
      assert.is.False(is_bench)
    end)

    it('returns true on benchmark functions', function()
      is_bench = utils.is_benchmark_test('BenchmarkExample')
      assert.is.True(is_bench)
    end)

    it('returns false on empty function name', function()
      is_bench = utils.is_benchmark_test('')
      assert.is.False(is_bench)
    end)
  end)

  describe('get_test_function_debug_args', function()
    it('with test function', function()
      local args = utils.get_test_function_debug_args('TestExample')

      assert.are.same(args, {
        '-test.run',
        '^TestExample$',
      })
    end)

    it('with benchmark function', function()
      local args = utils.get_test_function_debug_args('BenchmarkExample')

      assert.are.same(args, {
        '-test.bench',
        '^BenchmarkExample$',
        '-test.run',
        'a^',
      })
    end)
  end)
end)
