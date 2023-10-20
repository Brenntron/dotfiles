local M = {
  "nvim-tree/nvim-web-devicons",
  event = "VeryLazy",
}
function M.config()
  local devicons = require "nvim-web-devicons"

  devicons.set_icon {}
end

return M
