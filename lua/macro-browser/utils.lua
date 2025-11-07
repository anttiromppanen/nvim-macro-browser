local Constants = require("macro-browser.constants")
local M = {}

function M.text_with_left_padding(static_text, dynamic_test)
	return string.rep(" ", Constants.window_settings.heading_left_padding) .. static_text .. dynamic_test
end

return M
