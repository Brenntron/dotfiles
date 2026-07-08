return {
  "codethread/qmk.nvim",
  config = function()
    ---@type qmk.UserConfig
    local conf = {
      name = "LAYOUT_preonic_grid",
      layout = {
        "_ x x x x x x _ x x x x x x",
        "_ x x x x x x _ x x x x x x",
        "_ x x x x x x _ x x x x x x",
        "_ x x x x x x _ x x x x x x",
        "_ x x x x x x _ x x x x x x",
      },
    }
    require("qmk").setup(conf)
  end,
}
