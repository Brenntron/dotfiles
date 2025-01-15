local M = {
  "windwp/nvim-autopairs",
  event = "InsertEnter",
  opts = {
    check_ts = true, -- treesitter integration
    disable_filetype = { "TelescopePrompt", "spectre_panel" },
    disable_in_macro = false,
    disable_in_visualblock = false,
    enable_check_bracket_line = false,
    enable_afterquote = true,
    enable_moveright = true,
    fast_wrap = {
      chars = { "{", "[", "(", '"', "'" },
      check_comma = true,
      end_key = "$",
      highlight = "Search",
      highlight_grey = "Comment",
      keys = "qwertyuiopzxcvbnmasdfghjkl",
      map = "<M-e>",
      offset = 0, -- Offset from pattern match
      pattern = string.gsub([[ [%'%"%)%>%]%)%}%,] ]], "%s+", ""),
    },
    ignore_next_char = string.gsub([[ [%w%%%'%[%"%.] ]], "%s+", ""),
    map_bs = true,
    map_c_w = false,
    map_char = {
      all = "(",
      text = "{",
    },
    ts_config = {
      lua = { "string", "source" },
      javascript = { "string", "template_string" },
      java = false,
    },
  },
}

return M
