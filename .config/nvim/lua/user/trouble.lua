local M = {
		"folke/trouble.nvim",
		cmd = "TroubleToggle",
		dependencies = "nvim-tree/nvim-web-devicons",
		config = function()
			require("trouble").init({})
		end
	}

return M
