local M = { "sindrets/diffview.nvim", event = "BufRead" }

function M.config()
  require("diffview").setup {}
end

return M
