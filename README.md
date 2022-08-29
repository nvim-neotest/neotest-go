# neotest-go

This plugin provides a go(lang) adapter for the [Neotest](https://github.com/rcarriga/neotest) framework.

## Installation

Using packer:

```lua
use({
  'nvim-neotest/neotest',
  requires = {
    ...,
    'nvim-neotest/neotest-go',
  }
  config = function()
    require('neotest').setup({
      ...,
      adapters = {
        require('neotest-go'),
      }
    })
  end
})
```

You can also supply optional arguments to the setup function if you want to
enable experimental features or provide more arguments to `go test` command.

```lua
require("neotest").setup({
  adapters = {
    require("neotest-go")({
      experimental = {
        test_table = true,
      },
      args = { "-count=1", "-timeout=60s" }
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
