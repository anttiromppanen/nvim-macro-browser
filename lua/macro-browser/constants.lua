local C = {}

-- Window settings
C.window_settings = {
	relative = "editor",
	left_padding = 2,
	border_style = "minimal",
	border = "rounded",
	winblend = 10,
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
