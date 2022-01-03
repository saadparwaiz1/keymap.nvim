-- utilties for mapping keys
--- @class keymap
local keymap = {}

local __temp_map = {}

local map = vim.api.nvim_set_keymap
local bmap = vim.api.nvim_buf_set_keymap

-- Map Lua Functions and Strings
--- @param lhs string
--- @param rhs function|string
--- @param opts table
function keymap.map(lhs, rhs, opts)
	opts = opts or {}
	local create_map
	if opts.buffer then
		create_map = function(m, l, r, o)
			bmap(opts.buffer, m, l, r, o)
		end
	else
		create_map = map
	end
	local options = {
		expr = opts.expr,
		nowait = opts.nowait,
		script = opts.script,
		unique = opts.unique,
		silent = opts.silent == nil and true or (opts.silent or false),
		noremap = opts.noremap == nil and true or (opts.silent or false),
	}
	opts.mode = opts.mode or "n"
	if vim.is_callable(rhs) then
		options.callback = rhs
		rhs = ""
	end
	if type(opts.mode) == "table" then
		for _, v in pairs(opts.mode) do
			create_map(v, lhs, rhs, options)
		end
	else
		create_map(opts.mode, lhs, rhs, options)
	end
end

-- Delete Maps
---@param lhs string
---@param mode string
---@param buffer number
function keymap.del(lhs, mode, buffer)
	mode = mode or "n"
	local del_map
	if buffer then
		del_map = function(m, l)
			vim.api.nvim_buf_del_keymap(buffer, m, l)
		end
	else
		del_map = vim.api.nvim_del_keymap
	end

	if type(mode) == "table" then
		for _, v in pairs(mode) do
			del_map(v, lhs)
		end
	else
		del_map(mode, lhs)
	end
end

function keymap.tmp(lhs, rhs, opts)
	opts = opts or {}
	opts.buffer = opts.buffer or 0
	local mode = opts.mode or "n"
	local d_rhs = vim.tbl_filter(function (x)
	  return x['lhs'] == lhs
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
