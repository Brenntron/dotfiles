local M = {
  "rcarriga/nvim-notify",
  laxy = true
}

function M.config()
  vim.notify = require("notify")
end

return M
