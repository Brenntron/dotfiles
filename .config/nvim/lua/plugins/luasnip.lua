local M = {
  "L3MON4D3/LuaSnip",
  build = "make install_jsregexp",
  dependencies = {
    "rafamadriz/friendly-snippets"
  },
  config = function()
    local luasnip = require("luasnip")

    luasnip.filetype_extend("ruby", {"jekyll", "rails"})
    luasnip.filetype_extend("javascript", {"vue"})
    luasnip.filetype_extend("typescript", {"vue"})

    require("luasnip.loaders.from_vscode").lazy_load({paths = "~/.config/nvim/snippets"})
  end
}

return M
