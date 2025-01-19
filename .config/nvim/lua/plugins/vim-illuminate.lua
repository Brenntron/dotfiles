local M = {
  "RRethy/vim-illuminate",
  event = "VeryLazy",
  config = function ()
    require('illuminate').configure {
      filetypes_denylist = {
        "DiffviewFiles",
        "DressingInput",
        "DressingSelect",
        "NvimTree",
        "Outline",
        "TelescopePrompt",
        "Trouble",
        "alpha",
        "fugitive",
        "lazy",
        "lir",
        "mason",
        "minifiles",
        "netrw",
        "packer",
        "qf",
        "spectre_panel",
        "toggleterm",
      },
    }
  end
}

return M
