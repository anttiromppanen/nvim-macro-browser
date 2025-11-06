local M = {}
local C = require("macro-browser.constants")

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

	local text = string.rep(" ", C.left_padding) .. "🔴 Recording @" .. reg
	vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, { text })

	local opts = {
		relative = "editor",
		width = #text + 4,
		height = 1,
		row = 1,
		col = vim.o.columns - (#text + 6),
		style = C.border_style,
		border = C.border,
		noautocmd = true,
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
		pcall(vim.api.nvim_set_option_value, "winblend", C.winblend, { win = state.win })
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
