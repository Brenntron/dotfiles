-- Terminal: toggleterm.nvim (floating terminals)

require("toggleterm").setup({
  open_mapping = [[<c-\>]],
  direction = "float",
  hide_numbers = true,
  shade_terminals = true,
  shading_factor = 2,
  start_in_insert = true,
  insert_mappings = true,
  persist_size = true,
  close_on_exit = true,
  shell = "/bin/zsh",
  float_opts = {
    border = "rounded",
    winblend = 0,
  },
})
