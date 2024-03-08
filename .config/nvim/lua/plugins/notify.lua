local M = {
  "rcarriga/nvim-notify",
  lazy = false
}

function M.config()
  require("notify").setup({
    render = "minimal",
    stages = "slide",
  })
end

return M
