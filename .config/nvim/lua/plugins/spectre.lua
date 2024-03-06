local M = {
  "windwp/nvim-spectre",
  event = "BufRead",
  config = function()
    require("spectre").setup({
      is_insert_mode = true,
    })
  end,
}

return M
