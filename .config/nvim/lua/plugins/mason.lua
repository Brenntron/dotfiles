local M = {
  "williamboman/mason-lspconfig.nvim",
  commit = "e7b64c11035aa924f87385b72145e0ccf68a7e0a",
  cmd = "Mason",
  event = "BufReadPre",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "williamboman/mason.nvim",
  },
}

function M.config()
  local icons = require "utils.icons"

  require("mason").setup({
    ui = {
      border = "rounded",
      icons = icons.mason,
    },
    log_level = vim.log.levels.INFO,
    max_concurrent_installers = 4,
  })

  require("mason-lspconfig").setup {
    ensure_installed = require("utils.servers"),
    automatic_installation = true,
  }
end

return M
