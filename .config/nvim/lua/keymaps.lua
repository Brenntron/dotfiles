local utils = require "utils.keymaps-helpers"
local maps = utils.empty_map_table()

local sections = {
  b = { desc = "﬘ Buffer"},
  c = { desc = " Copilot"},
  d = { desc = " Dadbod UI" },
  g = { desc = "󰊢 Git" },
  l = { desc = " LSP" },
  m = { desc = "🏗 Mason"},
  n = { desc = "󰟢 Null-Ls" },
  r = { desc = "🧪 Tests" },
  t = { desc = "󰭎 Telescope" },
  s = { desc = "󱙝 Spectre" },
  v = { desc = " Vim"}
}

-- Normal --
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

-- Write file
maps.n["<leader>w"] = { "<cmd>w!<cr>", desc = "Write to file" }
maps.n["<leader>wq"] = { "<cmd>wq!<cr>", desc = "Write to file and quit" }

-- Quit
maps.n["<leader>q"] = { "<cmd>q<cr>", desc = "Quit" }

-- Visual --
-- Better paste
maps.v["p"] = { "P", desc = "Better paste" }

-- Stay in indent mode
maps.v["<"] = { "<gv", desc = "Indent to the left" }
maps.v[">"] = { ">gv", desc = "Indent to the right" }

-- Vim commands
maps.n["<leader>v"] = sections.v
maps.n["<leader>vl"] = { "<cmd>Lazy<cr>", desc = "Lazy Plugin Manager" }
maps.n["<leader>vm"] = { "<cmd>messages<cr>", desc = "Open messages" }
maps.n["<leader>vn"] = { "<cmd>Notifications<cr>", desc = "Open notifications" }
maps.n["<leader>vq"] = { "<cmd>q<cr>", desc = "Quit" }

-- Troubel lists for basic functionality
maps.n["<leader>vt"] = { desc = 'Trouble lists' }
maps.n["<leader>vtq"] = { function() require("trouble").toggle("quickfix") end, desc = "QuickFix" }
maps.n["<leader>vtl"] = { function() require("trouble").toggle("loclist") end, desc = "LocationList" }

-- Buffer commands
maps.n["<leader>b"] = sections.b
maps.n["<leader>bc"] = { "<cmd>bdelete<cr>", desc = "Close and delete buffer" }
maps.n["<leader>bd"] = { "<cmd>Bdelete<cr>", desc = "Delete buffer without closing the window" }

-- Plugins --

-- GitHub Copilot
maps.n["<leader>c"] = sections.c
maps.n["<leader>cd"] = { "<cmd>Copilot disable<cr>", desc = "Disable Copilot" }
maps.n["<leader>ce"] = { "<cmd>Copilot enable<cr>", desc = "Enable Copilot" }
maps.n["<leader>ch"] = { "<cmd>Copilot help<cr>", desc = "Display Copilot help page" }
maps.n["<leader>cp"] = { "<cmd>Copilot panel<cr>", desc = "Display up to 10 Copilot completions for current buffer."}
maps.n["<leader>csi"] = { "<cmd>Copilot signout<cr>", desc = "Signout of Copilot" }
maps.n["<leader>cst"] = { "<cmd>Copilot status<cr>", desc = "Display Copilot status" }

-- Comment
maps.n["<leader>/"] = { "<cmd>lua require('Comment.api').toggle.linewise.current()<CR>", desc = "Toggle comment line" }
maps.v["<leader>/"] =
  { "<esc><cmd>lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<CR>", desc = "Toggle comment line" }

-- Dad Bod UI
maps.n["<leader>u"] = sections.u
maps.n["<leader>ui"] = { "<cmd>DBUI<cr>", desc = "Open Dad Bod UI" }
maps.n["<leader>ua"] = { "<cmd>DBUIAddConnection", desc = "Add Dad Bod UI connection" }

-- NvimTree/Explorer
maps.n["<leader>e"] = { "<cmd>NvimTreeToggle<cr>", desc = "Toggle tree explorer" }

-- Telescope
maps.n["<leader>t"] = sections.t
maps.n["<leader>tbr"] = { "<cmd>Telescope file_browser path=%:p:h select_buffer=true<cr>", desc = "Open file browser" }
maps.n["<leader>tbu"] = { "<cmd>Telescope buffers<cr>", desc = "Find buffers" }
maps.n["<leader>tf"] = { "<cmd>Telescope find_files<cr>", desc = "Find files" }
maps.n["<leader>tl"] = { "<cmd>Telescope lazy<cr>", desc = "Lazy plugin info" }
maps.n["<leader>tn"] = { "<cmd>Telescope notify<cr>", desc = "Search message history" }
maps.n["<leader>tp"] = { "<cmd>Telescope projects<cr>", desc = "Find projects" }
maps.n["<leader>tw"] = { "<cmd>Telescope live_grep<cr>", desc = "Find words" }
maps.n["<leader>tz"] = { "<cmd>Telescope zoxide list", desc = "List directories" }
maps.n["<leader>tt"] = { "<cmd>Telescope toggleterm_manager", desc = "List Terminals" }

-- Telescope for DAP
maps.n["<leader>td"] = { desc = 'DAP' }
maps.n["<leader>tdb"] = { "<cmd>lua require'dap'.toggle_breakpoint()<cr>", desc = "Toggle breakpoint" }
maps.n["<leader>tdc"] = { "<cmd>lua require'dap'.continue()<cr>", desc = "Continue" }
maps.n["<leader>tdcm"] = { "<cmd>Telescope dap commands<cr>", desc = "Commands" }
maps.n["<leader>tdcn"] = { "<cmd>Telescope dap configurations<cr>", desc = "Config" }
maps.n["<leader>tdf"] = { "<cmd>Telescope dap frames<cr>", desc = "Frames" }
maps.n["<leader>tdi"] = { "<cmd>lua require'dap'.step_into()<cr>", desc = "Step into" }
maps.n["<leader>tdl"] = { "<cmd>Telescope dap list_breakpoints<cr>", desc = "List breakpoints" }
maps.n["<leader>tdrl"] = { "<cmd>lua require'dap'.run_last()<cr>", desc = "Run last" }
maps.n["<leader>tdO"] = { "<cmd>lua require'dap'.step_out()<cr>", desc = "Step out" }
maps.n["<leader>tdo"] = { "<cmd>lua require'dap'.step_over()<cr>", desc = "Step over" }
maps.n["<leader>tdr"] = { "<cmd>lua require'dap'.repl.toggle()<cr>", desc = "Toggle REPL" }
maps.n["<leader>tdt"] = { "<cmd>lua require'dap'.terminate()<cr>", desc = "Terminate" }
maps.n["<leader>tdu"] = { "<cmd>lua require'dapui'.toggle()<cr>", desc = "Toggle Dap UI" }
maps.n["<leader>tdv"] = { "<cmd>Telescope dap variables<cr>", desc = "Variables" }

-- Git
maps.n["<leader>g"] = sections.g
maps.n["<leader>gg"] = { "<cmd>LazyGit<cr>", desc = "Lazygit" }
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

-- Lsp
maps.n["<leader>l"] = sections.l
maps.n["<leader>li"] = { "<cmd>LspInfo<cr>", desc = "Lsp Info"}
maps.n["<leader>ll"] = { "<cmd>LspLog<cr>", desc = "Lsp Log"}
maps.n["<leader>lf"] = { "<cmd>lua vim.lsp.buf.format{ async = true, timeout_ms = 5000 }<cr>", desc = "Format file" }
maps.n["<leader>lgD"] = { "<cmd>lua vim.lsp.buf.declaration()<CR>", desc = "GoTo declaration" }
maps.n["<leader>lgd"] = { "<cmd>lua vim.lsp.buf.definition()<CR>", desc = "GoTo definition" }
maps.n["<leader>lK"] = { "<cmd>lua vim.lsp.buf.hover()<CR>", desc = "Hover" }
maps.n["<leader>lI"] = { "<cmd>lua vim.lsp.buf.implementation()<CR>", desc = "GoTo implementation" }
maps.n["<leader>lr"] = { "<cmd>lua vim.lsp.buf.references()<CR>", desc = "GoTo references" }
maps.n["<leader>ld"] = { "<cmd>lua vim.diagnostic.open_float()<CR>", desc = "Float diagnostic" }
maps.n["<leader>la"] = { "<cmd>lua vim.lsp.buf.code_action()<cr>", desc = "Code action" }
maps.n["<leader>lj"] = { "<cmd>lua vim.diagnostic.goto_next({buffer=0})<cr>", desc = "Next diagnostic" }
maps.n["<leader>lk"] = { "<cmd>lua vim.diagnostic.goto_prev({buffer=0})<cr>", desc = "Previous diagnostic" }
maps.n["<leader>lr"] = { "<cmd>lua vim.lsp.buf.rename()<cr>", desc = "Rename" }
maps.n["<leader>ls"] = { "<cmd>lua vim.lsp.buf.signature_help()<CR>", desc = "Signature help" }
maps.n["<leader>lq"] = { "<cmd>lua vim.diagnostic.setloclist()<CR>", desc = "Setloclist" }

-- Trouble for LSP
maps.n["<leader>lt"] = { desc = 'Trouble lists' }
maps.n["<leader>ltr"] = { function() require("trouble").toggle("lsp_references") end, desc = "References" }
maps.n["<leader>ltf"] = { function() require("trouble").toggle("lsp_definitions") end, desc = "Definitions" }
maps.n["<leader>ltq"] = { function() require("trouble").toggle("quickfix") end, desc = "QuickFix" }
maps.n["<leader>ltl"] = { function() require("trouble").toggle("loclist") end, desc = "LocationList" }

-- Mason
maps.n["<leader>m"] = sections.m
maps.n["<leader>mi"] = { "<cmd>Mason<cr>", desc = "Mason Control Panel" }
maps.n["<leader>ml"] = { "<cmd>MasonLog<cr>", desc = "Mason Log" }

-- None-Ls
maps.n["<leader>n"] = sections.n
maps.n["<leader>ni"] = { "<cmd>NullLsInfo<cr>", desc = "Null-Ls Info" }
maps.n["<leader>nl"] = { "<cmd>NullLsLog<cr>", desc = "Null-Ls Log"}

-- Trouble for None-Ls
maps.n["<leader>lt"] = { desc = 'Trouble Windows' }
maps.n["<leader>ntd"] = { function() require("trouble").toggle("document_diagnostics") end, desc = "Diagnostics" }
maps.n["<leader>ntw"] = { function() require("trouble").toggle("workspace_diagnostics") end, desc = "Workspace Diagnostics" }

-- Vim-Test
maps.n["<leader>r"] = sections.r
maps.n["<leader>rt"] = { "<cmd>TestNearest<cr>", desc = "Run the nearest test in this file" }
maps.n["<leader>rT"] = { "<cmd>TestFile<cr>", desc = "Run all tests in this file" }
maps.n["<leader>ra"] = { "<cmd>TestSuite<cr>", desc = "Run the test suite" }
maps.n["<leader>rl"] = { "<cmd>TestLast<cr>", desc = "Run the last test" }
maps.n["<leader>rg"] = { "<cmd>TestVisit<cr>", desc = "Visits the last run test file" }

-- Spectre
maps.n["<leader>s"] = sections.s
maps.n["<leader>so"] = { "<cmd>lua require('spectre').open()<cr>", desc = "Open Spectre" }
maps.n["<leader>sw"] =
  { "<cmd>lua require('spectre').open_visual({select_word=true})<cr>", desc = "Search current word" }
maps.n["<leader>sp"] =
  { "<cmd>lua require('spectre').open_file_search({select_word=true})<cr>", desc = "Search on current file" }

utils.set_mappings(maps)
