-- Trouble: pretty diagnostics, references, quickfix

require("trouble").setup({
  modes = {
    lsp = {
      win = { position = "right" },
    },
  },
})
