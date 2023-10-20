local M = {
  "nvim-telescope/telescope.nvim",
  commit = "74ce793a60759e3db0d265174f137fb627430355",
  cmd = "Telescope",
  dependencies = {
    {
      {
        "ahmedkhalf/project.nvim",
        commit = "8c6bad7d22eef1b71144b401c9f74ed01526a4fb",
        event = "VeryLazy",
      },
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
        lazy = true,
      },
    },
  },
  event = "Bufenter",
  lazy = true,
}

function M.config()
  local actions = require "telescope.actions"
  local icons = require "utils.icons"
  local telescope = require "telescope"

  telescope.setup {
    defaults = {
      color_devicons = true,
      entry_prefix = "   ",
      initial_mode = "insert",
      layout_config = {},
      layout_strategy = nil,
      mappings = {
        i = {
          ["<C-n>"] = actions.cycle_history_next,
          ["<C-p>"] = actions.cycle_history_prev,

          ["<C-j>"] = actions.move_selection_next,
          ["<C-k>"] = actions.move_selection_previous,
        },
        n = {
          ["<esc>"] = actions.close,
          ["j"] = actions.move_selection_next,
          ["k"] = actions.move_selection_previous,
          ["q"] = actions.close,
        },
      },
      path_display = { "smart" },
      prompt_prefix = icons.ui.Telescope .. " ",
      selection_caret = icons.ui.Forward .. " ",
      selection_strategy = "reset",
      set_env = { ["COLORTERM"] = "truecolor" },
      sorting_strategy = nil,
      vimgrep_arguments = {
        "rg",
        "--color=never",
        "--no-heading",
        "--with-filename",
        "--line-number",
        "--column",
        "--smart-case",
        "--hidden",
        "--glob=!.git/",
      },
    },
    pickers = {
      buffers = {
        theme = "dropdown",
        previewer = false,
        mappings = {
          i = {
            ["<C-d>"] = actions.delete_buffer,
          },
          n = {
            ["dd"] = actions.delete_buffer,
          },
        },
      },
      colorscheme = {
        enable_preview = true,
      },
      find_files = {
        theme = "dropdown",
        previewer = false,
      },
      grep_string = {
        theme = "dropdown",
      },
      live_grep = {
        theme = "dropdown",
      },
      planets = {
        show_pluto = true,
        show_moon = true,
      },
      lsp_declarations = {
        theme = "dropdown",
        initial_mode = "normal",
      },
      lsp_definitions = {
        theme = "dropdown",
        initial_mode = "normal",
      },
      lsp_references = {
        theme = "dropdown",
        initial_mode = "normal",
      },
      lsp_implementations = {
        theme = "dropdown",
        initial_mode = "normal",
      },
    },
    extensions = {
      fzf = {
        fuzzy = true, -- false will only do exact matching
        override_generic_sorter = true, -- override the generic sorter
        override_file_sorter = true, -- override the file sorter
        case_mode = "smart_case", -- or "ignore_case" or "respect_case"
      },
    },
  }

  telescope.load_extension 'fzf'
  telescope.load_extension "projects"
end

return M
