return {
  "linux-cultist/venv-selector.nvim",
  dependencies = {
    {
      "folke/snacks.nvim",
      version = "*",
      dependencies = { "nvim-lua/plenary.nvim" },
    }, -- optional: you can also use fzf-lua, snacks, mini-pick instead.
  },
  ft = "python", -- Load when opening Python files
  keys = {
    { "<leader>v", "<cmd>VenvSelect<cr>" }, -- Open picker on keymap
  },
  opts = { -- this can be an empty lua table - just showing below for clarity.
    search = {}, -- if you add your own searches, they go here.
    options = {}, -- if you add plugin options, they go here.
  },
}
