-- utilties for mapping keys
--- @class keymap
local keymap = {}

local __temp_map = {}

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
		remap = not (opts.noremap == nil and true or (opts.noremap or false)),
    buffer = opts.buffer
	}
	opts.mode = opts.mode or "n"
  vim.keymap.set(opts.mode, lhs, rhs, options)
end

-- Delete Maps
---@param lhs string
---@param mode string
---@param buffer number
function keymap.del(lhs, mode, buffer)
  vim.keymap.del(mode or "n", lhs, { buffer = buffer })
end

function keymap.tmp(lhs, rhs, opts)
	opts = opts or {}
	opts.buffer = opts.buffer or 0
	local mode = opts.mode or "n"
	local d_rhs = vim.tbl_filter(function (x)
	  return x['lhs'] == lhs:gsub('<leader>', vim.g.mapleader)
	end, vim.api.nvim_buf_get_keymap(opts.buffer, mode))
  d_rhs = d_rhs or {}
  d_rhs = d_rhs[1] or {}
	__temp_map[mode] = __temp_map[mode] or {}
	__temp_map[mode][lhs] = d_rhs
	keymap.map(lhs, rhs, opts)
end

function keymap.revert(lhs, mode)
	mode = mode or "n"
	local opts = __temp_map[mode][lhs]
  __temp_map[mode][lhs] = nil
	keymap.del(lhs, mode, 0)
	if opts["rhs"] == nil and opts["callback"] == nil then
		return
	end
	opts["rhs"] = opts["rhs"] or opts["callback"]
  if opts["rhs"] == nil then
    return
  end
  keymap.map(lhs, opts["rhs"], opts)
end

-- Wrapper over neovim keymap api to set keymaps using a table
--- @param mps table
--- @param defaults table
--- @return nil
function keymap.maps(mps, defaults)
	for _, v in pairs(mps) do
		v = vim.tbl_extend("keep", v, defaults or {})
		keymap.map(v[1], v[2], v)
	end
end

return keymap
