local M = {
  "cappyzawa/trim.nvim",
  event = "BufRead",
}

function M.config()
  require("trim").setup { trim_last_line = false }
end

return M
