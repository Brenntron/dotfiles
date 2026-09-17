local wk = require("which-key")

-- Python specific keymappings
wk.add({
  { "<leader>P", group = "Python", icon = " " },

  { "<leader>Pu", group = "uv" },
  { "<leader>Pur", "<cmd>UVRunFile<cr>", desc = "Run current file" },
  { "<leader>Pus", "<cmd>UVRunSelection<cr>", desc = "Run selected code" },
  { "<leader>Puf", "<cmd>UVRunFunction<cr>", desc = "Run specific function" },
  { "<leader>Pue", "<cmd>lua Snacks.picker.pick('uv_venv')<cr>", desc = "Environment management" },
  { "<leader>Pui", "<cmd>UVInit<cr>", desc = "Initialize UV project" },
  { "<leader>Pua", "<cmd>lua vim.ui.input({prompt = 'Enter package name: '}, function(input) if input and input ~= '' then require('uv').run_command('uv add ' .. input) end end)<cr>", desc = "Add package" },
  { "<leader>Pud", "<cmd>lua require('uv').remove_package()<cr>", desc = "Remove package" },
  { "<leader>Puc", "<cmd>lua require('uv').run_command('uv sync')<cr>", desc = "Sync packages" },
}, { mode = "n" })

-- Set indent depth to 4 from standard 2
vim.opt_local.shiftwidth = 4
vim.opt_local.tabstop = 4
vim.opt_local.softtabstop = 4
