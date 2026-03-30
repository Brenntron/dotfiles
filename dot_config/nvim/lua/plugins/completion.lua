-- Completion: blink.cmp

require("blink.cmp").setup({
  keymap = {
    preset = "default",
    ["<C-y>"] = { "select_and_accept" },
    ["<C-u>"] = { "scroll_documentation_up", "fallback" },
    ["<C-d>"] = { "scroll_documentation_down", "fallback" },
  },
  appearance = {
    use_nvim_cmp_as_default = false,
    nerd_font_variant = "mono",
  },
  sources = {
    default = { "lsp", "path", "snippets", "buffer", "lazydev" },
    providers = {
      lazydev = {
        name = "LazyDev",
        module = "lazydev.integrations.blink",
        score_offset = 100,
      },
    },
  },
  completion = {
    accept = { auto_brackets = { enabled = true } },
    menu = {
      draw = {
        treesitter = { "lsp" },
      },
    },
    documentation = {
      auto_show = true,
      auto_show_delay_ms = 200,
    },
  },
  fuzzy = { implementation = "prefer_rust_with_warning" },
  snippets = { preset = "mini_snippets" },
  signature = { enabled = true },
})
