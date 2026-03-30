-- Editor: flash.nvim, which-key.nvim, persistence.nvim

-- Flash (fast navigation/motions)
require("flash").setup({
  modes = {
    search = { enabled = false },
    char = { jump_labels = true },
  },
})

-- Which-key (keymap hints and discoverability)
require("which-key").setup({
  preset = "modern",
  delay = function(ctx)
    return ctx.plugin and 0 or 200
  end,
  spec = {
    {
      mode = { "n", "v" },
      { "<leader>b", group = "buffer" },
      { "<leader>c", group = "code" },
      { "<leader>f", group = "file/find" },
      { "<leader>g", group = "git" },
      { "<leader>gh", group = "hunks" },
      { "<leader>q", group = "quit/session" },
      { "<leader>s", group = "search" },
      { "<leader>u", group = "ui/toggle" },
      { "<leader>w", group = "windows" },
      { "<leader>x", group = "diagnostics/quickfix" },
      { "<leader><tab>", group = "tabs" },
    },
  },
})

-- Persistence (session management)
require("persistence").setup({
  options = vim.opt.sessionoptions:get(),
})
