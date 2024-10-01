# neotest-go

This plugin provides a go(lang) adapter for the [Neotest](https://github.com/rcarriga/neotest) framework.

## Installation

Using packer:

```lua
use({
  "nvim-neotest/neotest",
  requires = {
    "nvim-neotest/neotest-go",
    -- Your other test adapters here
  },
  config = function()
    -- get neotest namespace (api call creates or returns namespace)
    local neotest_ns = vim.api.nvim_create_namespace("neotest")
    vim.diagnostic.config({
      virtual_text = {
        format = function(diagnostic)
          local message =
            diagnostic.message:gsub("\n", " "):gsub("\t", " "):gsub("%s+", " "):gsub("^%s+", "")
          return message
        end,
      },
    }, neotest_ns)
    require("neotest").setup({
      -- your neotest config here
      adapters = {
        require("neotest-go"),
      },
    })
  end,
})

```

The above mentioned `vim.diagnostic.config` is optional but recommended if you
enabled the `diagnostic` option of neotest. Especially [testify](https://github.com/stretchr/testify)
makes heavy use of tabs and newlines in the error messages, which reduces the readability of
the generated virtual text otherwise.

You can also supply optional arguments to the setup function if you want to
enable experimental features, provide more arguments to `go test` command, or set the `CC` env variable in the test context.

```lua
require("neotest").setup({
  adapters = {
    require("neotest-go")({
      experimental = {
        test_table = true,
      },
      args = { "-count=1", "-timeout=60s" },
      c_compiler = "clang",
    })
  }
})
```

By default `go test` runs for currecnt package only. If you want to run it recursively you need to set:
```lua
require("neotest").setup({
  adapters = {
    require("neotest-go")({
      recursive_run = true
    })
  }
})
```

## Usage

_NOTE_: all usages of `require('neotest').run.run` can be mapped to a command in your config (this is not included and should be done by the user)

#### Test single function

To test a single test hover over the test and run `require('neotest').run.run()`

**NOTE:** Please note that `testify` test methods cannot be run using this function
as `go test` cannot run these tests individually using the `-run` flag.

#### Test file

To test a file run `require('neotest').run.run(vim.fn.expand('%'))`

#### Test directory

To test a directory run `require('neotest').run.run("path/to/directory")`

#### Test suite

To test the full test suite run `require('neotest').run.run("path/to/root_project")`
e.g. `require('neotest').run.run(vim.fn.getcwd())`, presuming that vim's directory is the same as the project root

#### Additional arguments

Additional arguments for the go test command can be sent using the `extra_args` field e.g.

```lua
require('neotest').run.run({path, extra_args = {"-race"}})
```

## Contributing

This project is maintained by the nvim golang community. Please raise a PR if you are interested in adding new functionality or fixing any bugs
If you are unsure of how this plugin works please read the [Writing adapters](https://github.com/nvim-neotest/neotest#writing-adapters) section of the Neotest README.

If you are new to `lua` please follow any of the following resources:

- https://learnxinyminutes.com/docs/lua/
- https://www.lua.org/manual/5.1/
- https://github.com/nanotee/nvim-lua-guide

### Unit tests

Unit tests are written with the [plenary busted framework](https://github.com/nvim-lua/plenary.nvim/blob/master/TESTS_README.md). They can be run in a shell with

```bash
nvim --headless -c ':PlenaryBustedDirectory lua/spec'
```
