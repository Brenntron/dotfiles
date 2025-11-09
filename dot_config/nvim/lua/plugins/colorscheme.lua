return {

  -- tokyonight
  {
    "folke/tokyonight.nvim",
    lazy = true,
    opts = { style = "moon" },
  },

  -- catppuccin
  {
    "catppuccin/nvim",
    lazy = true,
    name = "catppuccin",
    opts = {
      flavour = "macchiato", -- latte, frappe, macchiato, mocha
      backgrorund = {
        light = "latte",
        dark = "macchiato",
      },
      auto_integrations = true,
    },
    specs = {
      "akinsho/bufferline.nvim",
      after = "catppuccin",
      opts = {
        highlights = require("catppuccin.special.bufferline").get_theme(),
      }
    },
  },
}
