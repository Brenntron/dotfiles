local M = {
  "akinsho/bufferline.nvim",
  event = { "BufReadPre", "BufAdd", "BufNew", "BufReadPost" },
  dependencies = {
    {
      "nvim-tree/nvim-web-devicons",
    },
    {
      "catppuccin/nvim",
    },
  },
  opts = {
    options = {
      close_command = "Bdelete! %d", -- can be a string | function, see "Mouse actions"
      offsets = { { filetype = "NvimTree", text = "", padding = 1 } },
      right_mouse_command = "Bdelete! %d", -- can be a string | function, see "Mouse actions"
      separator_style = "thin", -- | "thick" | "thin" | { 'any', 'any' },
      show_tab_indicators = true, -- | "always" | "never",
    },
    -- tokyo night highlights
    -- highlights = {
    --   buffer_selected = {
    --     bold = true,
    --     italic = false,
    --   },
    highlights = require("catppuccin.groups.integrations.bufferline").get {
      styles = { "italic", "bold" },
    },
  }
}

return M
