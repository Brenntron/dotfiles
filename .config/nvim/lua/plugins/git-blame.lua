local M = {
  "f-person/git-blame.nvim",
  event = "BufRead",
  init = function()
    vim.cmd("highlight default link gitblame SpecialComment")
  end,
  opts = { enabled = true }
}

return M
