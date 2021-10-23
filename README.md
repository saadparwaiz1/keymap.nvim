# Keymap.nvim

Another Generic Keymap Plugin For Neovim

## Installation

```lua
use {
  'saadparwaiz1/keymap.nvim'
}
```

## Usage

### Map a single function or value

```lua
-- map for normal with mode with default options (silent and noremap)
keymap.map('K', vim.lsp.buf.hover)

-- map for a different mode/options
keymap.map('K', vim.lsp.buf.hover, {mode='i', noremap=false, expr=true})

-- map for various modes
keymap.map('K', vim.lsp.buf.hover, {mode={'i', 'n'}, noremap=false, expr=true})

-- buffer local map by default current buffer
keymap.map_local('K', vim.lsp.buf.hover)

-- buffer local map for specific buffer
keymap.map_local('K', vim.lsp.buf.hover, {bufnr=40})
```
### Delete a Keymap

```lua
-- Delete Keymap K from insert mode
keymap.del('K', 'i')

-- Delete Keymap K from insert and normal mode
keymap.del('K', {'i', 'n'})

-- Delete buffer local keymap
keymap.del_local('K', 'i')
```

### Temporary Map a Key For Buffer

```lua
-- same opts as keymap.map_local
keymap.tmp('K', vim.lsp.buf.hover)

-- this keymap can then be reverted to it's orignal mapping as follows
-- second parameter is optional and defaults to 'n' for normal mode
keymap.revert('K')
```


### Map a Dictionary Containing Keymaps

```lua
keymaps = {
  {
    'K',
    vim.lsp.buf.hover,
    silent = false,
    noremap = false
  },
  {
    'jk',
    '<cmd>echo mapped for both insert and normal<CR>',
    mode = {'i', 'n'}
  }
}

-- first argument is Keymaps
-- second argument are default options for all maps in dicts
-- The second argument is optional and defaults to {noremap=true, silent=true}
-- override options for specific keymaps within the table as shown
keymap.maps(keymaps, {noremap=true, silent=true})

```
