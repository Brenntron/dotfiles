-- Terminal: toggleterm.nvim

require("toggleterm").setup({
  open_mapping = [[<c-\>]],
  direction = "float",
  float_opts = {
    border = "rounded",
    winblend = 0,
  },
  shade_terminals = true,
  shading_factor = 2,
  start_in_insert = true,
  insert_mappings = true,
  persist_size = true,
  close_on_exit = true,
  shell = vim.o.shell,
})
