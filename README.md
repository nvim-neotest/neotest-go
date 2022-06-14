# neotest-go

This plugin provides a go(lang) adapter for the [Neotest](https://github.com/rcarriga/neotest) framework.

## Status:

**Work in progress 🚧**.

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

## Usage

See neotest's documentation for more information on how to run tests.

## Contributing

This project is maintained by the nvim golang community. Please raise a PR if you are interested in adding new functionality or fixing any bugs
If you are unsure of how this plugin works please read the [Writing adapters](https://github.com/nvim-neotest/neotest#writing-adapters) section of the Neotest README.

If you are new to `lua` please follow any of the following resources:

- https://learnxinyminutes.com/docs/lua/
- https://www.lua.org/manual/5.1/
- https://github.com/nanotee/nvim-lua-guide
