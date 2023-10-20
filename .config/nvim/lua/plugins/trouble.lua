local M = {
  "folke/trouble.nvim",
  cmd = { "TroubleToggle" },
  dependencies = { "nvim-tree/nvim-web-devicons" }
}

function M.config()
  require("trouble").setup {}
end

return M
