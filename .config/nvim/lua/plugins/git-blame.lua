local M = {
		"f-person/git-blame.nvim",
		event = "BufRead",
	}

function M.config()
  vim.cmd("highlight default link gitblame SpecialComment")
  require("gitblame").setup({ enabled = true })
end

return M
