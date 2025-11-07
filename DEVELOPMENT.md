# DEVELOPMENT

## Running the plugin locally

```bash
:lua vim.opt.rtp:append("~/Documents/nvim_plugins/nvim-macro-browser")
:luafile ~/Documents/nvim_plugins/nvim-macro-browser/plugin/macro-browser.lua
```

## TODO

- Fix @@ (rerun last macro) default behavior
- Refactor variable names and magic numbers
- Refactor macro-browser/macros.lua
- Add a small delay for @ (show macros), so that fast macro use doesn't trigger the popup window
- Feature to add description for a macro
- Feature to show saved macros
- Feature to save a macro
- README.md documentation
- :help documentation
- Tab toggle between macros / registers (currently only macros -> registers)
- Enable custom user configurations
  - Window
    - Window placement
    - Window colors
    - Enable / disable heading icons
