local M = {
  "folke/which-key.nvim",
  event = "VeryLazy",
  config = function()
    local opts = {
      icons = {
        group = "", -- symbol prepended to a group
      },
    }

    require("which-key").setup(opts)
    require("utils.keymaps-helpers").which_key_register()
  end,
}

return M
