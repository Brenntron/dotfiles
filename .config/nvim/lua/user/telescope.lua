local M = {
  "nvim-telescope/telescope.nvim",
  event = "Bufenter",
  cmd = { "Telescope" },
  dependencies = {
    {
      "nvim-telescope/telescope-project.nvim",
      "nvim-telescope/telescope-fzy-native.nvim",
    },
  },
}

local actions = require "telescope.actions"

M.opts = {
  defaults = {
    prompt_prefix = " ",
    selection_caret = " ",
    path_display = { "smart" },
    file_ignore_patterns = { ".git/", "node_modules", "vendor" },
    mappings = {
      i = {
        ["<Down>"] = actions.move_selection_next,
        ["<Up>"] = actions.move_selection_previous,
        ["<C-j>"] = actions.move_selection_next,
        ["<C-k>"] = actions.move_selection_previous,
      },
    },
  },
  extensions = {
    fzy_native = {
      override_generic_sorter = false,
      override_file_sorter = true,
    }
  }
}

return M
