local M = {
  "norcalli/nvim-colorizer.lua",
  event = "Bufenter",
  ft = { "coffee", "conf", "css", "javascript", "scss", "yaml" },
  opts = {
    "coffee",
    "css",
    "lua",
    "ruby",
    "vim",
    "toml",
    html = { names = false},
    javascript = { names = false },
    yaml = { names = false },
  }, {
    RGB = true, -- #RGB hex codes
    RRGGBB = true, -- #RRGGBB hex codes
    RRGGBBAA = true, -- #RRGGBBAA hex codes
    rgb_fn = true, -- CSS rgb() and rgba() functions
    hsl_fn = true, -- CSS hsl() and hsla() functions
    css = true, -- Enable all CSS features: rgb_fn, hsl_fn, names, RGB, RRGGBB
    css_fn = true, -- Enable all CSS *functions*: rgb_fn, hsl_fn
  },
}

return M
