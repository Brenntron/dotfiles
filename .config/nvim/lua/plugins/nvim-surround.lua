local M = {
  "kylechui/nvim-surround",
  event = "VeryLazy"
}

function M.config()
  require('nvim-surround').setup {}
end

return M
