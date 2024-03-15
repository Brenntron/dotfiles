local M = {
  "nvim-telescope/telescope.nvim",
  cmd = "Telescope",
  dependencies = {
    {
      "ahmedkhalf/project.nvim",
      event = "VeryLazy",
    },
    { "nvim-lua/popup.nvim" },
    { "nvim-lua/plenary.nvim" },
    { "nvim-telescope/telescope-dap.nvim" },
    {
      "nvim-telescope/telescope-file-browser.nvim",
      event = "VeryLazy",
    },
    {
      "nvim-telescope/telescope-fzf-native.nvim",
      build = "make",
    },
    {
      "nvim-telescope/telescope-live-grep-args.nvim",
      version = "^1.0.0"
    },
    {
      "jvgrootveld/telescope-zoxide",
    },
    {
      "rcarriga/nvim-notify",
    },
    {
      "ryanmsnyder/toggleterm-manager.nvim",
      config = true
    },
    {
      "tsakirist/telescope-lazy.nvim"
    }
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
        initial_mode = "normal",
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
      lazy = {
        theme = "dropdown",
        show_icon = true,
        mappings = {
          open_in_browser = "<C-o>",
          open_in_find_files = "<C-f>",
          open_in_live_grep = "<C-g>",
          open_in_terminal = "<C-t>",
          open_plugins_picker = "<C-b>", -- Works only after having called first another action
          open_lazy_root_find_files = "<C-r>f",
          open_lazy_root_live_grep = "<C-r>g",
          change_cwd_to_plugin = "<C-c>d",
        },
        -- Configuration that will be passed to the window that hosts the terminal
        -- For more configuration options check 'nvim_open_win()'
        terminal_opts = {
          relative = "editor",
          style = "minimal",
          border = "rounded",
          title = "Telescope lazy",
          title_pos = "center",
          width = 0.5,
          height = 0.5,
        },
      },
      project = {
        base_dirs = {
          "~/.config/nvim/",
        },
        hidden_files = true,
        on_project_select = function(prompt_bufnr)
          local project_actions = require "telescope._extensions.project.actions"
          project_actions.change_working_directory(prompt_bufnr, false)
        end,
        order_by = "asc",
        search_by = "title",
        theme = "dropdown",
      },
      zoxide = {
        keepinsert = true,
      }
    },
  }

  telescope.load_extension "dap"
  telescope.load_extension "fzf"
  telescope.load_extension "lazy"
  telescope.load_extension "live_grep_args"
  telescope.load_extension "notify"
  telescope.load_extension "projects"
  telescope.load_extension "zoxide"
end

return M
