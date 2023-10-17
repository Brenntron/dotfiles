local M = {
  "cappyzawa/trim.nvim",
  event = "BufRead",
  config = function()
    require("trim").setup { trim_last_line = false }
  end,
}

return M
