return {
  "catppuccin/nvim",
  lazy = true,
  name = "catppuccin",
  opts = {
    auto_integrations = true,
    colorscheme = "catppuccin-macchiato",
  },
  specs = {
    {
      "akinsho/bufferline.nvim",
      optional = true,
      opts = function(_, opts)
        if (vim.g.colors_name or ""):find("catppuccin") then
          opts.highlights = require("catppuccin.groups.integrations.bufferline").get_theme
        end
      end,
    },
  },
}
