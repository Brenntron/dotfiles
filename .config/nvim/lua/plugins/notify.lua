local M = {
  "rcarriga/nvim-notify",
  lazy = true
}

function M.config()
  vim.notify = require("notify")
end

return M
