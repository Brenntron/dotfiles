local M = {
  "RRethy/vim-illuminate",
  commit = "3bd2ab64b5d63b29e05691e624927e5ebbf0fb86",
  event = "VeryLazy",
}

function M.config()
  require("illuminate").configure {
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

return M
