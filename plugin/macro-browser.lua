-- plugin/macro-browser.lua
-- This file should ONLY bootstrap the plugin, nothing more

local function setup_macro_browser()
	-- Ensure global state exists
	if not _G.macro_popup_recorded then
		_G.macro_popup_recorded = {}
	end

	-- Load and initialize the main plugin module
	local macro_browser = require("macro-browser")

	if macro_browser and macro_browser.setup then
		macro_browser.setup()
	end
end

-- Run setup when plugin is loaded
setup_macro_browser()
