local M = {
  "lukas-reineke/indent-blankline.nvim",
  event = "BufReadPre",
  main = "ibl",
  opts = {
    exclude = {
      filetypes = {
        "checkhealth",
        "gitcommit",
        "lspinfo",
        "man",
        "NvimTree",
        "help",
        "packer",
        "TelescopePrompt",
        "TelescopeResults",
      },
    },
  },
}

return M
