local M = {
  "williamboman/mason-lspconfig.nvim",
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
    ensure_installed = require("utils.servers").server_list,
    automatic_installation = true,
  }
end

return M
