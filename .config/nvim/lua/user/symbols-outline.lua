local M = {
  "simrat39/symbols-outline.nvim",
  lazy = true
}

function M.config()
  require("symbols-outline").init()
end

return M
