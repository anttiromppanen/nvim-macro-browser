local M = {}
local Constants = require("macro-browser.constants")
local Utils = require("macro-browser.utils")

-- Store window and buffer references
local state = {
	win = nil,
	buf = nil,
}

--- Show recording popup
---@param reg string Register name being recorded
function M.show(reg)
	M.hide() -- Clean up any existing popup

	state.buf = vim.api.nvim_create_buf(false, true)
	vim.bo[state.buf].bufhidden = "wipe"

	local text = Utils.text_with_left_padding(Constants.text_prompts.recording, reg)

	vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, { text })

	-- Popup Layout Calculations
	local window_width = #text + Constants.window_settings.padding_horizontal
	local window_height = 1 -- Single-line popup
	local col_position = vim.o.columns - (window_width + Constants.window_settings.window_right_offset)

	-- Window options
	local opts = {
		relative = Constants.window_settings.relative,
		width = window_width,
		height = window_height,
		row = Constants.window_settings.row_position,
		col = col_position,
		style = Constants.window_settings.border_style,
		border = Constants.window_settings.border,
		noautocmd = Constants.window_settings.noautocmd,
	}

	-- state.win = vim.api.nvim_open_win(state.buf, false, opts)
	-- possible fix for precognition
	state.win = vim.api.nvim_open_win(
		state.buf,
		false,
		vim.tbl_extend("force", opts, {
			focusable = false,
			noautocmd = true,
		})
	)

	-- Use pcall in case window creation failed
	if state.win and vim.api.nvim_win_is_valid(state.win) then
		pcall(vim.api.nvim_set_option_value, "winblend", Constants.window_settings.winblend, { win = state.win })
	end
end

--- Hide recording popup
function M.hide()
	if state.win and vim.api.nvim_win_is_valid(state.win) then
		pcall(vim.api.nvim_win_close, state.win, true)
	end
	state.win = nil
	state.buf = nil
end

return M
