-- utilties for mapping keys
--- @class keymap
local keymap = {}

local __del_map = {}
local __del_map_local = {}

local __temp_map = {}

local map = vim.api.nvim_set_keymap
local buf_map = vim.api.nvim_buf_set_keymap

__MapStore = __MapStore or {}

-- Store anoynmous functions for use later
keymap.store = __MapStore

-- create string for mapping and set up autocmds
---@param rhs string
---@param opts table
---@return string
local function create_mapping(rhs, opts)
  local id = keymap.create(rhs)
  local fmt_str = [[<cmd>lua require('personal.keymap')[%s]()<CR>]]
  if opts.expr then
    fmt_str = [[luaeval("require('personal.keymap')[%s]()")]]
  end
  local str_rhs = string.format(fmt_str, tostring(id))
  if opts.bufnr then
    local str_autocmd = [[autocmd BufDelete %s ++once :lua require('personal.keymap').remove(%d)]]
    str_autocmd = string.format(str_autocmd, vim.api.nvim_buf_get_name(opts.bufnr or 0), id)
    vim.api.nvim_exec(str_autocmd, false)
  end
  return str_rhs, id
end

-- create an entry for anoynmous function
--- @param f function
--- @return number
function keymap.create(f)
  local c = vim.tbl_contains(keymap.store, f)
  if c then
    return c
  end
  table.insert(keymap.store, f)
  return #keymap.store
end

-- remove an entry for anoynmous function
--- @param d number
function keymap.remove(d)
  keymap.store[d] = nil
end

-- Map Lua Functions and Strings
--- @param lhs string
--- @param rhs function|string
--- @param opts table
function keymap.map(lhs, rhs, opts)
  opts = opts or {}
  local options = {
    expr = opts.expr,
    nowait = opts.nowait,
    script = opts.script,
    unique = opts.unique,
    silent = opts.silent == nil and true or (opts.silent or false),
    noremap = opts.noremap == nil and true or (opts.silent or false),
  }
  opts.mode = opts.mode or 'n'
  if not vim.is_callable(rhs) then
    if vim.startswith(rhs, '<Plug>') then
      options.noremap = false
    end
    if type(opts.mode) == 'table' then
      for _, v in pairs(opts.mode) do
        __del_map[v] = __del_map[v] or {}
        __del_map[v][lhs] = true
        map(v, lhs, rhs, options)
      end
    else
      __del_map[opts.mode] = __del_map[opts.mode] or {}
      __del_map[opts.mode][lhs] = true
      map(opts.mode, lhs, rhs, options)
    end
    return
  end
  local str_rhs, id = create_mapping(rhs, opts)
  if type(opts.mode) == 'table' then
    for _, v in pairs(opts.mode) do
        __del_map[v] = __del_map[v] or {}
        __del_map[v][lhs] = id
      map(v, lhs, str_rhs, options)
    end
  else
      __del_map[opts.mode] = __del_map[opts.mode] or {}
      __del_map[opts.mode][lhs] = id
    map(opts.mode, lhs, str_rhs, options)
  end
end

-- Buffer Map Lua Functions and Strings
--- @param lhs string
--- @param rhs function|string
--- @param opts table
function keymap.map_local(lhs, rhs, opts)
  opts = opts or {}
  local options = {
    expr = opts.expr,
    nowait = opts.nowait,
    script = opts.script,
    unique = opts.unique,
    silent = opts.silent == nil and true or (opts.silent or false),
    noremap = opts.noremap == nil and true or (opts.silent or false),
  }
  opts.mode = opts.mode or 'n'
  opts.bufnr = opts.bufnr or 0
  if not vim.is_callable(rhs) then
    if vim.startswith(rhs, '<Plug>') then
      options.noremap = false
    end
    if type(opts.mode) == 'table' then
      for _, v in pairs(opts.mode) do
        __del_map_local[v] = __del_map_local[v] or {}
        __del_map_local[v][lhs] = true
        buf_map(opts.bufnr, v, lhs, rhs, options)
      end
    else
        __del_map_local[opts.mode] = __del_map_local[opts.mode] or {}
        __del_map_local[opts.mode][lhs] = true
      buf_map(opts.bufnr, opts.mode, lhs, rhs, options)
    end
    return
  end
  local str_rhs, id = create_mapping(rhs, opts)
  if type(opts.mode) == 'table' then
    for _, v in pairs(opts.mode) do
      __del_map_local[v] = __del_map_local[v] or {}
      __del_map_local[v][lhs] = id
      buf_map(opts.bufnr, v, lhs, str_rhs, options)
    end
  else
    __del_map_local[opts.mode] = __del_map_local[opts.mode] or {}
    __del_map_local[opts.mode][lhs] = id
    buf_map(opts.bufnr, opts.mode, lhs, str_rhs, options)
  end
end

-- Delete Buffer Local Maps
---@param lhs string
---@param mode string
---@param bufnr number
function keymap.del_local(lhs, mode, bufnr)
  mode = mode or 'n'
  bufnr = bufnr or 0
  if type(mode) == "table" then
    for _,v in pairs(mode) do
      local rhs = __del_map_local[v][lhs]
      if type(rhs) == 'number' then
        keymap.remove(rhs)
      end
      vim.api.nvim_buf_del_keymap(bufnr, v, lhs)
    end
  else
    local rhs = __del_map_local[mode][lhs]
    if type(rhs) == 'number' then
      keymap.remove(rhs)
    end
    vim.api.nvim_buf_del_keymap(bufnr, mode, lhs)
  end
end

-- Delete Maps
---@param lhs string
---@param mode string
function keymap.del(lhs, mode)
  mode = mode or 'n'
  if type(mode) == "table" then
    for _, v in pairs(mode) do
      local rhs = __del_map[v][lhs]
      if type(rhs) == 'number' then
        keymap.remove(rhs)
      end
      if rhs ~= nil then
        vim.api.nvim_del_keymap(v, lhs)
      end
    end
  else
    local rhs = __del_map[mode][lhs]
    if type(rhs) == 'number' then
      keymap.remove(rhs)
    end
    if rhs ~= nil then
      vim.api.nvim_del_keymap(mode, lhs)
    end
  end
end

function keymap.tmp(lhs, rhs, opts)
  opts = opts or {}
  local mode = opts.mode or 'n'
  local d_rhs = vim.fn.maparg(lhs, mode, false, true)
  __temp_map[mode] = __temp_map[mode] or {}
  __temp_map[mode][lhs] = d_rhs
  keymap.map_local(lhs, rhs, opts)
end

function keymap.revert(lhs, mode)
  mode = mode or 'n'
  local opts = __temp_map[mode][lhs]
  keymap.del_local(lhs, mode)
  if opts['rhs'] == nil then
    return
  end
  opts.expr = opts.expr == 1
  opts.script = opts.script == 1
  opts.silent = opts.silent == 1
  opts.nowait = opts.nowait == 1
  opts.noremap = opts.noremap == 1
  keymap.map_local(lhs, opts['rhs'], opts)
end

-- Wrapper over neovim keymap api to set keymaps using a table
--- @param mps table
--- @param defaults table
--- @return nil
function keymap.maps(mps, defaults)
  for _, v in pairs(mps) do
    v = vim.tbl_extend('keep', v, defaults or {})
    keymap.map(v[1], v[2], v)
  end
end

setmetatable(keymap, {
  __index = keymap.store,
})

return keymap
