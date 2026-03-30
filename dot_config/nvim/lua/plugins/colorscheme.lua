-- Catppuccin colorscheme (macchiato)

require("catppuccin").setup({
  flavour = "macchiato",
  background = {
    light = "latte",
    dark = "macchiato",
  },
  auto_integrations = true,
  integrations = {
    blink_cmp = true,
    bufferline = true,
    flash = true,
    gitsigns = true,
    indent_blankline = { enabled = true },
    lsp_trouble = true,
    mason = true,
    mini = { enabled = true },
    native_lsp = { enabled = true },
    noice = true,
    notify = true,
    snacks = true,
    treesitter = true,
    which_key = true,
  },
})

vim.cmd.colorscheme("catppuccin")
