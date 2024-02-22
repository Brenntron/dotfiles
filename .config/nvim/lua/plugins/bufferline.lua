local M = {
  "akinsho/bufferline.nvim",
  event = { "BufReadPre", "BufAdd", "BufNew", "BufReadPost" },
  dependencies = {
    {
      "famiu/bufdelete.nvim",
    },
  },
}
function M.config()
  local colors = require('tokyonight.colors').setup()

  require("bufferline").setup {
    options = {
      close_command = "Bdelete! %d", -- can be a string | function, see "Mouse actions"
      right_mouse_command = "Bdelete! %d", -- can be a string | function, see "Mouse actions"
      offsets = { { filetype = "NvimTree", text = "", padding = 1 } },
      separator_style = "thin", -- | "thick" | "thin" | { 'any', 'any' },
    },
    highlights = {
      fill = {
        fg = { attribute = colors.fg_dark, highlight = "TabLine" },
        bg = { attribute = colors.bg_dark, highlight = "TabLine" },
      },
      background = {
        fg = { attribute = colors.fg_dark, highlight = "TabLine" },
        bg = { attribute = colors.bg_dark, highlight = "TabLine" },
      },
      buffer_visible = {
        fg = { attribute = colors.fg_dark, highlight = "TabLine" },
        bg = { attribute = colors.bg_dark, highlight = "TabLine" },
      },
      close_button = {
        fg = { attribute = colors.fg_dark, highlight = "TabLine" },
        bg = { attribute = colors.bg_dark, highlight = "TabLine" },
      },
      close_button_visible = {
        fg = { attribute = colors.fg_dark, highlight = "TabLine" },
        bg = { attribute = colors.bg_dark, highlight = "TabLine" },
      },
      tab_selected = {
        fg = { attribute = colors.fg_dark, highlight = "Normal" },
        bg = { attribute = colors.bg_dark, highlight = "Normal" },
      },
      tab = {
        fg = { attribute = colors.fg_dark, highlight = "TabLine" },
        bg = { attribute = colors.bg_dark, highlight = "TabLine" },
      },
      tab_close = {
        -- fg = {attribute='fg',highlight='LspDiagnosticsDefaultError'},
        fg = { attribute = colors.fg_dark, highlight = "TabLineSel" },
        bg = { attribute = colors.bg_dark, highlight = "Normal" },
      },
      duplicate_selected = {
        fg = { attribute = colors.fg_dark, highlight = "TabLineSel" },
        bg = { attribute = colors.bg_dark, highlight = "TabLineSel" },
        italic = true,
      },
      duplicate_visible = {
        fg = { attribute = colors.fg_dark, highlight = "TabLine" },
        bg = { attribute = colors.bg_dark, highlight = "TabLine" },
        italic = true,
      },
      duplicate = {
        fg = { attribute = colors.fg_dark, highlight = "TabLine" },
        bg = { attribute = colors.bg_dark, highlight = "TabLine" },
        italic = true,
      },
      modified = {
        fg = { attribute = colors.fg_dark, highlight = "TabLine" },
        bg = { attribute = colors.bg_dark, highlight = "TabLine" },
      },
      modified_selected = {
        fg = { attribute = colors.fg_dark, highlight = "Normal" },
        bg = { attribute = colors.bg_dark, highlight = "Normal" },
      },
      modified_visible = {
        fg = { attribute = colors.fg_dark, highlight = "TabLine" },
        bg = { attribute = colors.bg_dark, highlight = "TabLine" },
      },
      separator = {
        fg = { attribute = colors.bg_dark, highlight = "TabLine" },
        bg = { attribute = colors.bg_dark, highlight = "TabLine" },
      },
      separator_selected = {
        fg = { attribute = colors.bg_dark, highlight = "Normal" },
        bg = { attribute = colors.bg_dark, highlight = "Normal" },
      },
      indicator_selected = {
        fg = { attribute = colors.fg_dark, highlight = "LspDiagnosticsDefaultHint" },
        bg = { attribute = colors.bg_dark, highlight = "Normal" },
      },
    },
  }
end

return M
