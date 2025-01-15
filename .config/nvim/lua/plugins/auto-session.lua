local M = {
  "rmagatti/auto-session",
  lazy = false,
  dependencies = {
    'nvim-telescope/telescope.nvim'
  },
  opts = {
    auto_session_suppress_dirs = { "~", "~/.config" , "/" },
    session_lens = {
      buftypes_to_ignore = {},
      bypass_session_save_file_types = { 'alpha', 'dashboard' },
      load_on_setup = true,
      theme_conf = { border = true },
      previewer = false,
      mappings = {
        delete_session = { "i", "<C-D>" },
        alternate_session = { "i", "<C-S>" }
      }
    }
  },
}

return M
