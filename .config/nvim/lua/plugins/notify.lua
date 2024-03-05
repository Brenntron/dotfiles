local M = {
  "rcarriga/nvim-notify",
  lazy = true
}

function M.config()
  vim.notify = require("notify").setup({
    render = "simple",
    stages = "slide",
  })
end

return M
