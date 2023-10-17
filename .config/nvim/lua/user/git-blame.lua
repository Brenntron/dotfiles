local M = {
		"f-person/git-blame.nvim",
		event = "BufRead",
		config = function()
			vim.cmd("highlight default link gitblame SpecialComment")
			require("gitblame").init({ enabled = false })
		end
	}

return M
