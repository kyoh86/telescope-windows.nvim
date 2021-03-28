# telescope-windows.nvim

`telescope-windows` is an extension for
[telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) that lists windows.

## Installation

```lua
use{
  'nvim-telescope/telescope-windows.nvim',
  requires = {
    'nvim-telescope/telescope.nvim',
  },
  config = function()
    require'telescope'.load_extension'windows'
  end,
}
```

## Usage

`:Telescope windows`

Running `windows` and list windows.
Selecting one, you can focus it.

# LICENSE

[![MIT License](http://img.shields.io/badge/license-MIT-blue.svg)](http://www.opensource.org/licenses/MIT)

This is distributed under the [MIT License](http://www.opensource.org/licenses/MIT).
