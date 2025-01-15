local M = {
  "SmiteshP/nvim-navic",
  opts = {
    icons = {
      File = "󰈙 ",
      Module= " ",
      Namespace= "󰌗 ",
      Package = " ",
      Class = "󰌗 ",
      Method = "󰆧 ",
      Property = " ",
      Field = " ",
      Constructor = " ",
      Enum = "󰕘",
      Interface = "󰕘",
      Function = "󰊕 ",
      Variable = "󰆧 ",
      Constant = "󰏿 ",
      String = "󰀬 ",
      Number = "󰎠 ",
      Boolean = "◩ ",
      Array = "󰅪 ",
      Object = "󰅩 ",
      Key = "󰌋 ",
      Null = "󰟢 ",
      Enummember = " ",
      Struct = "󰌗 ",
      Event = " ",
      Operator = "󰆕 ",
      Typeparameter = "󰊄 ",
    },
    lsp = {
      auto_attach = false,
      preference = nil,
    },
    highlight = false,
    separator = " > ",
    depth_limit = 0,
    depth_limit_indicator = "..",
    safe_output = true,
    lazy_update_context = false,
    click = false,
    format_text = function(text)
      return text
    end,
  }
}

return M
