# Neotest-go

This plugin provides a go(lang) adapter for the [Neotest](https://github.com/rcarriga/neotest) framework.
**It is currently a work in progress**. It will transferred to the official neotest organisation (once it's been created).

## Installation

Using packer:

```lua
  use({
    'rcarriga/neotest',
    requires = {
      ...,
      'akinsho/neotest-go',
    })
```

## Usage

See neotest's documentation for more information on how to run tests.

## Feature requests

Please do note that _I do not intend to implement feature requests_, this repo is an initial starting point for the nvim golang community.
Hopefully once it is more stable _go users will be able to contribute to the project_. For my own part I only intend to implement functionality that
I use in daily workflow.
