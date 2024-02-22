local M = {
  "nvim-lualine/lualine.nvim",
  dependencies = {
    'nvim-tree/nvim-web-devicons',
    'AndreM222/copilot-lualine',
  },
  lazy = false,
}

function M.config()
  local icons = require "utils.icons"
  local diff = {
    "diff",
    colored = true,
    symbols = {
      added = icons.git.LineAdded,
      modified = icons.git.LineModified,
      removed = icons.git.LineRemoved
    }, -- Changes the symbols used by the diff.
  }
  local diagnostics = {
    "diagnostics",
    sources = { "nvim_diagnostic" },
    symbols = {
      error = icons.diagnostics.Error,
      warn = icons.diagnostics.Warning,
      info = icons.diagnostics.Information,
      hint = icons.diagnostics.Hinta,
    }
  }

  require("lualine").setup {
    options = {
      component_separators = { left = "|", right = "|" },
      section_separators = { left = "", right = "" },
      ignore_focus = { "NvimTree" },
      -- theme = 'dracula-nvim',
      theme = 'tokyonight',
      icons_enabled = true,
      always_divide_middle = true,
    },
    sections = {
      lualine_a = { "mode" },
      lualine_b = { "branch", diff, diagnostics },
      lualine_c = { "filename" },
      lualine_x = { "copilot", "encoding", "fileformat", "filetype" },
      lualine_y = { "progress" },
      lualine_z = { "location" },
    },
    inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = { 'filename' },
        lualine_x = { 'location' },
        lualine_y = {},
        lualine_z = {}
    },
    extensions = { "quickfix", "man", "fugitive" },
  }
end

return M
