local M = {
  "tamago324/nlsp-settings.nvim",
  dependencies = {
    "williamboman/mason.nvim"
  }
}

function M.config()
  local nlspsettings = require "nlspsettings"

  nlspsettings.setup {
    config_home = vim.fn.stdpath "config" .. "/lsp-settings",
    local_settings_dir = ".nlsp-settings",
    local_settings_root_markers_fallback = { ".git" },
    append_default_schemas = true,
    loader = "json",
  }
end

return M
