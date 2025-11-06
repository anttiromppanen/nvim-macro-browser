local C = {}

C.left_padding = 2
C.border_style = "minimal"
C.border = "rounded"
C.winblend = 10

-- Namespace for highlights (add this here)
C.namespace = vim.api.nvim_create_namespace("macro_popup")

return C
