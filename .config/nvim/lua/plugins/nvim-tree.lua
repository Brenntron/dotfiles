local M = {
  "kyazdani42/nvim-tree.lua",
  event = "VimEnter",
  config = function()
    local icons = require "utils.icons"
    local function on_attach(bufnr)
      local api = require "nvim-tree.api"

      local function opts(desc)
        return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
      end

      api.config.mappings.default_on_attach(bufnr)

      vim.keymap.set("n", "l", api.node.open.edit, opts "Open")
      vim.keymap.set("n", "<CR>", api.node.open.edit, opts "Open")
      vim.keymap.set("n", "o", api.node.open.edit, opts "Open")
      vim.keymap.set("n", "h", api.node.navigate.parent_close, opts "Close Directory")
      vim.keymap.set("n", "v", api.node.open.vertical, opts "Open: Vertical Split")
    end

    -- local tree_cb = require("nvim-tree.config").nvim_tree_callback
    require("nvim-tree").setup {
      diagnostics = {
        enable = true,
        icons = {
          error = icons.diagnostics.BoldError,
          hint = icons.diagnostics.BoldHint,
          info = icons.diagnostics.BoldInformation,
          warning = icons.diagnostics.BoldWarning,
        },
        severity = {
          max = vim.diagnostic.severity.HINT,
          min = vim.diagnostic.severity.ERROR,
        },
        show_on_dirs = true,
      },
      filters = { custom = { "^.git$" } },
      on_attach = on_attach,
      renderer = {
        add_trailing = false,
        full_name = false,
        icons = {
          git_placement = "before",
          glyphs = {
            default = icons.ui.Text,
            folder = {
              arrow_closed = icons.ui.ChevronRight,
              arrow_open = icons.ui.ChevronShortDown,
              default = icons.ui.Folder,
              empty = icons.ui.EmptyFolder,
              empty_open = icons.ui.EmptyFolderOpen,
              open = icons.ui.FolderOpen,
              symlink = icons.ui.FolderSymlink,
              symlink_open = icons.ui.FolderOpen,
            },
            git = {
              deleted = icons.git.FileDeleted,
              ignored = icons.git.FileIgnored,
              renamed = icons.git.FileRenamed,
              staged = icons.git.FileStaged,
              unmerged = icons.git.FileUnmerged,
              unstaged = icons.git.FileUnstaged,
              untracked = icons.git.FileUntracked,
            },
            symlink = icons.ui.FileSymlink
          },
          padding = " ",
          symlink_arrow = icons.ui.symlink_arrow,
        },
        group_empty = false,
        highlight_git = false,
        highlight_opened_files = "none",
        indent_markers = {
          enable = false,
          icons = {
            corner = icons.ui.corner,
            edge = icons.ui.edge,
            item = icons.ui.item,
            none = icons.ui.none,
          },
          inline_arrows = true,
        },
        indent_width = 2,
        root_folder_label = ":t",
        special_files = { "Makefile", "README.md", "readme.md", ".obsidian" },
        symlink_destination = true,
      },
      sync_root_with_cwd = true,
      respect_buf_cwd = true,
      update_focused_file = {
        enable = true,
        debounce_delay = 15,
        ignore_list = {},
        update_root = true,
      },
      view = {
        number = true,
        relativenumber = true,
        side = "left",
        width = 50,
      },
    }
  end,
}

return M
