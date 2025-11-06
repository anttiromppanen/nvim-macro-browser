-- lua/macro_browser/init.lua
local M = {}
local macros = require("macro-browser.macros")
local popup = require("macro-browser.floating")

-- Default configuration
local defaults = {
	macro_key = "@", -- can be overridden by user
}

-- highlight definitions
vim.api.nvim_set_hl(0, "MacroPopupRegister", { bold = true, fg = "#89b4fa" }) -- bright blue for register
vim.api.nvim_set_hl(0, "MacroPopupText", { fg = "#6c7086" }) -- dim gray text

-- Try to auto-detect if @ was remapped
local function detect_macro_key()
	local maps = vim.api.nvim_get_keymap("n")
	for _, map in ipairs(maps) do
		if map.lhs ~= "@" and map.rhs and map.rhs:match("@") then
			return map.lhs
		end
	end
	return "@"
end

-- Store autocmd IDs for cleanup
local autocmd_ids = {}

--- Setup function
---@param opts table|nil user config
function M.setup(opts)
	opts = opts or {}

	-- Clean up existing autocmds if any
	if autocmd_ids.RecordingEnter then
		vim.api.nvim_del_autocmd(autocmd_ids.RecordingEnter)
	end
	if autocmd_ids.RecordingLeave then
		vim.api.nvim_del_autocmd(autocmd_ids.RecordingLeave)
	end

	-- Merge config
	local detected = detect_macro_key()
	M.config = vim.tbl_deep_extend("force", defaults, {
		macro_key = opts.macro_key or detected or "@",
	})

	-- Create autocmds for recording popup
	autocmd_ids.RecordingEnter = vim.api.nvim_create_autocmd("RecordingEnter", {
		callback = function()
			local reg = vim.fn.reg_recording()
			_G.macro_popup_recorded[reg] = true
			popup.show(reg)
		end,
	})

	autocmd_ids.RecordingLeave = vim.api.nvim_create_autocmd("RecordingLeave", {
		callback = function()
			popup.hide()
		end,
	})

	-- Setup keymap for running macros
	vim.keymap.set("n", M.config.macro_key, function()
		macros.prompt_and_run()
	end, { noremap = true, silent = true, desc = "Run recorded macro with popup" })
end

-- Cleanup function for reloading
function M.cleanup()
	-- Clear autocmds
	for _, id in pairs(autocmd_ids) do
		pcall(vim.api.nvim_del_autocmd, id)
	end
	autocmd_ids = {}
end

return M
