local Constants = require("macro-browser.constants")
local Utils = require("macro-browser.utils")
local M = {}

-- Store window and buffer references
local state = {
	win = nil,
	buf = nil,
}

_G.macro_popup_recorded = _G.macro_popup_recorded or {}

----------------------------------------------------------------------
-- Get list of registers containing macros
----------------------------------------------------------------------
local function get_macros(opts)
	opts = opts or {}
	local show_all = opts.show_all or false
	local macros = {}

	-- Registers a-z and 0-9
	local registers = {}
	for i = string.byte("a"), string.byte("z") do
		registers[#registers + 1] = string.char(i)
	end
	for i = 0, 9 do
		registers[#registers + 1] = tostring(i)
	end

	for _, reg in ipairs(registers) do
		local info = vim.fn.getreginfo(reg)
		if info and info.regcontents and #info.regcontents > 0 then
			local content = table.concat(info.regcontents, "\\n")

			-- Filter junk/system registers
			local is_valid = not content:match("^:") and not content:match("<80>") and #content > 0

			if is_valid then
				local was_recorded = _G.macro_popup_recorded[reg] or false
				if show_all or was_recorded then
					macros[#macros + 1] = {
						name = reg,
						value = content:gsub("\n", "\\n"),
					}
				end
			end
		end
	end

	return macros
end

----------------------------------------------------------------------
-- Show floating window listing macros
----------------------------------------------------------------------
function M.show(opts)
	opts = opts or {}
	local macros = get_macros(opts)

	if #macros == 0 then
		vim.notify("No macros recorded", vim.log.levels.INFO)
		return
	end

	state.buf = vim.api.nvim_create_buf(false, true)
	vim.bo[state.buf].bufhidden = "wipe"
	vim.bo[state.buf].buftype = "nofile"

	local heading = Utils.text_with_left_padding(Constants.text_prompts.show_macros, "")
	local lines = { heading, "" }

	for _, m in ipairs(macros) do
		lines[#lines + 1] = string.format("  %s → %s", m.name, m.value)
	end

	vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)

	-- Apply highlights for register names
	for i, m in ipairs(macros) do
		local line_nr = i + 1 -- because line 1 = heading, line 2 = blank
		local line_text = string.format("  %s → %s", m.name, m.value)

		-- Highlight register name
		vim.api.nvim_buf_add_highlight(
			state.buf,
			Constants.namespace,
			"MacroPopupRegister",
			line_nr,
			2, -- after leading spaces
			2 + #m.name -- end of register
		)

		-- Dim everything after the arrow
		local arrow_col = line_text:find("→")
		if arrow_col then
			vim.api.nvim_buf_add_highlight(state.buf, Constants.namespace, "MacroPopupText", line_nr, arrow_col, -1)
		end
	end

	local width = 0
	for _, line in ipairs(lines) do
		width = math.max(width, vim.fn.strdisplaywidth(line))
	end

	local opts_win = {
		relative = Constants.window_settings.relative,
		width = math.min(width + 4, vim.o.columns - 10),
		height = math.min(#lines + 2, 15),
		row = 2,
		col = vim.o.columns - math.min(width + 6, vim.o.columns - 4),
		style = Constants.window_settings.border_style,
		border = Constants.window_settings.border,
		noautocmd = true,
	}

	-- state.win = vim.api.nvim_open_win(state.buf, true, opts_win)
	-- possible fix for precognition
	state.win = vim.api.nvim_open_win(
		state.buf,
		false,
		vim.tbl_extend("force", opts_win, {
			focusable = false,
			noautocmd = true,
		})
	)

	if state.win and vim.api.nvim_win_is_valid(state.win) then
		pcall(vim.api.nvim_set_option_value, "winblend", 10, { win = state.win })
		vim.keymap.set("n", "q", M.close, { buffer = state.buf, nowait = true, silent = true })
		vim.keymap.set("n", "<Esc>", M.close, { buffer = state.buf, nowait = true, silent = true })
	end
end

----------------------------------------------------------------------
-- Close popup
----------------------------------------------------------------------
function M.close()
	if state.win and vim.api.nvim_win_is_valid(state.win) then
		pcall(vim.api.nvim_win_close, state.win, true)
	end
	state.win = nil
	state.buf = nil
end

----------------------------------------------------------------------
-- Prompt user for macro register and execute it safely
----------------------------------------------------------------------
function M.prompt_and_run()
	-- Show only recorded macros at first
	M.show({ show_all = false })
	vim.cmd("redraw")

	local ok, char_nr = pcall(vim.fn.getchar)
	if not ok then
		M.close()
		return
	end

	local char = vim.fn.nr2char(char_nr)

	-- Toggle show_all with ? or <Tab>
	if char == "?" or char == "\t" then
		M.close()
		M.show({ show_all = true })
		vim.cmd("redraw")

		local ok2, char_nr2 = pcall(vim.fn.getchar)
		if not ok2 then
			M.close()
			return
		end
		char = vim.fn.nr2char(char_nr2)
	end

	M.close()

	-- Abort on ESC or invalid
	if char == "\27" or char == "" then
		return
	end

	if not char:match(Constants.register_matcher_regex) then
		vim.notify("Invalid macro register: " .. char, vim.log.levels.WARN)
		return
	end

	local reg_info = vim.fn.getreginfo(char)
	if not reg_info or not reg_info.regcontents or #reg_info.regcontents == 0 then
		vim.notify("Register @" .. char .. " is empty", vim.log.levels.WARN)
		return
	end

	------------------------------------------------------------------
	-- ✅ SAFELY EXECUTE MACRO WITHOUT BREAKING PRECOGNITION
	------------------------------------------------------------------
	vim.schedule(function()
		local ok_precog, precog = pcall(require, "precognition")

		-- Has the one-time first-run fix already been done?
		local do_cleanup = not _G.__macro_popup_precog_initialized
		_G.__macro_popup_precog_initialized = true -- mark as completed for future runs

		-- Only hide/show precognition on first macro run to fix stale-hint bug.
		if do_cleanup and ok_precog and precog then
			-- Try hide() if available
			if type(precog.hide) == "function" then
				pcall(precog.hide)
			else
				-- Fallback command (safe no-op if unsupported)
				pcall(vim.cmd, "silent! Precognition hide")
			end
		end

		-- Run macro cleanly (important: noautocmd prevents hint-generation)
		local ok_run, err = pcall(function()
			vim.cmd("noautocmd normal! @" .. char)
		end)
		if not ok_run then
			vim.notify("Macro error: " .. tostring(err), vim.log.levels.ERROR)
		end

		-- Restore precognition visibility only on first run
		if do_cleanup and ok_precog and precog then
			vim.defer_fn(function()
				if type(precog.show) == "function" then
					pcall(precog.show)
				else
					pcall(vim.cmd, "silent! Precognition show")
				end
			end, 80)
		end
	end)
end

return M
