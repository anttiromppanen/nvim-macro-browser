local C = {}

-- Window settings
C.window_settings = {
	-- Window style
	relative = "editor",
	heading_left_padding = 2,
	border_style = "minimal",
	border = "rounded",
	winblend = 10,
	noautocmd = true,

	-- Window position and size
	padding_horizontal = 4,
	padding_vertical = 2,
	max_height = 15,
	window_right_offset = 6,
	min_screen_margin = 10,
	row_position = 2,
}

-- Text prompts for window / notifies
C.text_prompts = {
	recording = "🔴 Recording @",
	show_macros = "🟢 Macros:",
	no_macros = "No macros recorded",
}

-- Namespace for highlights
C.namespace = vim.api.nvim_create_namespace("macro_popup")

-- Register match regex
C.register_matcher_regex = "^[a-z0-9]$"

return C
