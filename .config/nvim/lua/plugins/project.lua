local M = {
  "ahmedkhalf/project.nvim",
  commit = "8c6bad7d22eef1b71144b401c9f74ed01526a4fb",
  event = "VeryLazy",
}

function M.config()
  require("project_nvim").setup {
    active = true,
    detection_methods = { "pattern" },
    exclude_dirs = {},
    ignore_lsp = {},
    manual_mode = false,
    on_config_done = nil,
    patterns = { ".git", "Makefile", "package.json" },
    scope_chdir = "global",
    show_hidden = false,
    silent_chdir = true,
  }
end

return M
