local M = {
  "windwp/nvim-spectre",
  event = "BufRead",
  opts = {
    is_insert_mode = true,
    use_trouble_qf = true,
    replace_engine = {
      ["sed"] = {
        cmd = "sed",
        args = {"-i", "", "-E"},
      },
    }
  },
}

return M
