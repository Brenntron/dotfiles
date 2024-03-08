local M = {
  "lukas-reineke/indent-blankline.nvim",
  event = "BufReadPre",
  main = "ibl",
}

function M.config()
  require("ibl").setup({
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
  })
end

return M
