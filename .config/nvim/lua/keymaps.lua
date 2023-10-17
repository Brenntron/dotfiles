local utils = require "utils.keymaps-helpers"
local maps = utils.empty_map_table()

local sections = {
  d = { desc = " Debug" },
  f = { desc = "󰭎 Telescope" },
  g = { desc = "󰊢 Git" },
  l = { desc = " LSP" },
  n = { desc = " Neovim Config" },
  s = { desc = "󱙝 Spectre" },
  t = { desc = "󱉯 Trouble" },
}

-- Standart --
-- Better window navigation
maps.n["<C-h>"] = { "<C-w>h", desc = "Navigate to the left split" }
maps.n["<C-j>"] = { "<C-w>j", desc = "Navigate to the bottom split" }
maps.n["<C-k>"] = { "<C-w>k", desc = "Navigate to the top split" }
maps.n["<C-l>"] = { "<C-w>l", desc = "Navigate to the right split" }

-- Resize with arrows
maps.n["<C-Up>"] = { "<cmd>resize -2<cr>", desc = "Shrink window horizontally" }
maps.n["<C-Down>"] = { "<cmd>resize +2<cr>", desc = "Increase window horizontally" }
maps.n["<C-Left>"] = { "<cmd>vertical -2<cr>", desc = "Shrink window vertically" }
maps.n["<C-Right>"] = { "<cmd>vertical +2<cr>", desc = "Increase window vertically" }

-- Navigate buffers
maps.n["<S-l>"] = { "<cmd>bnext<cr>", desc = "Next buffer" }
maps.n["<S-h>"] = { "<cmd>bprevious<cr>", desc = "Previous buffer" }

-- Clear highlights
maps.n["<leader>h"] = { "<cmd>nohlsearch<cr>", desc = "Clear highlights" }

-- Close buffer
maps.n["<S-q>"] = { "<cmd>Bdelete!<cr>", desc = "Close buffer" }

-- Save buffer
maps.n["<S-w>"] = { "<cmd>w!<cr>", desc = "Save buffer" }

-- Neovim Config
maps.n["<leader>n"] = sections.n
maps.n["<leader>nod"] = { "<cmd>e ~/.config/nvim/init.lua<cr>", desc = "Open config directory" }
maps.n["<leader>ns"] = { "<cmd>ReloadNvim<cr>", desc = "Reload Neovim's configuration" }

-- Better paste
maps.v["p"] = { "P", desc = "Better paste" }

-- Visual --
-- Stay in indent mode
maps.v["<"] = { "<gv", desc = "Indent to the left" }
maps.v[">"] = { ">gv", desc = "Indent to the right" }

-- Plugins --

-- Comment
maps.n["<leader>/"] = { "<cmd>lua require('Comment.api').toggle.linewise.current()<CR>", desc = "Toggle comment line" }
maps.v["<leader>/"] =
  { "<esc><cmd>lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<CR>", desc = "Toggle comment line" }

-- Dap
maps.n["<leader>d"] = sections.d
maps.n["<leader>db"] = { "<cmd>lua require'dap'.toggle_breakpoint()<cr>", desc = "Toggle breakpoint" }
maps.n["<leader>dc"] = { "<cmd>lua require'dap'.continue()<cr>", desc = "Continue" }
maps.n["<leader>di"] = { "<cmd>lua require'dap'.step_into()<cr>", desc = "Step into" }
maps.n["<leader>do"] = { "<cmd>lua require'dap'.step_over()<cr>", desc = "Step over" }
maps.n["<leader>dO"] = { "<cmd>lua require'dap'.step_out()<cr>", desc = "Step out" }
maps.n["<leader>dr"] = { "<cmd>lua require'dap'.repl.toggle()<cr>", desc = "Toggle REPL" }
maps.n["<leader>dl"] = { "<cmd>lua require'dap'.run_last()<cr>", desc = "Run last" }
maps.n["<leader>du"] = { "<cmd>lua require'dapui'.toggle()<cr>", desc = "Toggle Dap UI" }
maps.n["<leader>dt"] = { "<cmd>lua require'dap'.terminate()<cr>", desc = "Terminate" }

-- Git
maps.n["<leader>g"] = sections.g
maps.n["<leader>gg"] = { "<cmd>lua _LAZYGIT_TOGGLE()<cr>", desc = "Lazygit" }
maps.n["<leader>gl"] = { "<cmd>lua require('gitsigns').blame_line()<cr>", desc = "View Git blame" }
maps.n["<leader>gL"] = { "<cmd>lua require('gitsigns').blame_line { full = true }<cr>", desc = "View full Git blame" }
maps.n["<leader>gp"] = { "<cmd>lua require('gitsigns').preview_hunk()<cr>", desc = "Preview Git hunk" }
maps.n["<leader>gh"] = { "<cmd>lua require('gitsigns').reset_hunk()<cr>", desc = "Reset Git hunk" }
maps.n["<leader>gr"] = { "<cmd>lua require('gitsigns').reset_buffer()<cr>", desc = "Reset Git buffer" }
maps.n["<leader>gs"] = { "<cmd>lua require('gitsigns').stage_hunk()<cr>", desc = "Stage Git hunk" }
maps.n["<leader>gS"] = { "<cmd>lua require('gitsigns').stage_buffer()<cr>", desc = "Stage Git buffer" }
maps.n["<leader>gu"] = { "<cmd>lua require('gitsigns').undo_stage_hunk()<cr>", desc = "Unstage Git hunk" }
maps.n["<leader>gd"] = { "<cmd>lua require('gitsigns').diffthis()<cr>", desc = "View Git diff" }
maps.n["]g"] = { "<cmd>lua require('gitsigns').next_hunk()", desc = "Next Git hunk" }
maps.n["[g"] = { "<cmd>lua require('gitsigns').prev_hunk()<cr>", desc = "Previous Git hunk" }

-- Easy-Align
maps.n["<leader>ea"] = { "<Plug>(EasyAlign)", desc = "Align text" }
maps.v["<leader>ea"] = { "<Plug>(EasyAlign)", desc = "Align block" }

-- Lsp
maps.n["<leader>l"] = sections.l
maps.n["<leader>lf"] = { "<cmd>lua vim.lsp.buf.format{ async = true, timeout_ms = 5000 }<cr>", desc = "Format file" }

-- NvimTree
maps.n["<leader>e"] = { "<cmd>NvimTreeToggle<cr>", desc = "Toggle explorer" }

maps.n["<leader>f"] = sections.f
maps.n["<leader>ff"] = { "<cmd>Telescope find_files<cr>", desc = "Find files" }
maps.n["<leader>ft"] = { "<cmd>Telescope live_grep<cr>", desc = "Find words" }
maps.n["<leader>fp"] = { "<cmd>Telescope projects<cr>", desc = "Find projects" }
maps.n["<leader>fb"] = { "<cmd>Telescope buffers<cr>", desc = "Find buffers" }

-- Spectre
maps.n["<leader>s"] = sections.s
maps.n["<leader>so"] = { "<cmd>lua require('spectre').open()<cr>", desc = "Open Spectre" }
maps.n["<leader>sw"] =
  { "<cmd>lua require('spectre').open_visual({select_word=true})<cr>", desc = "Search current word" }
maps.n["<leader>sp"] =
  { "<cmd>lua require('spectre').open_file_search({select_word=true})<cr>", desc = "Search on current file" }

-- Trouble
maps.n["<leader>t"] = sections.t
maps.n["<leader>tr"] = { function() require("trouble").toggle("lsp_references") end, desc = "References" }
maps.n["<leader>tf"] = { function() require("trouble").toggle("lsp_definitions") end, desc = "Definitions" }
maps.n["<leader>td"] = { function() require("trouble").toggle("document_diagnostics") end, desc = "Diagnostics" }
maps.n["<leader>tq"] = { function() require("trouble").toggle("quickfix") end, desc = "QuickFix" }
maps.n["<leader>tl"] = { function() require("trouble").toggle("loclist") end, desc = "LocationList" }
maps.n["<leader>tw"] = { function() require("trouble").toggle("workspace_diagnostics") end, desc = "Workspace Diagnostics" }

utils.set_mappings(maps)
