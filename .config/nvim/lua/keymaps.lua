local utils = require "utils.keymaps-helpers"
local maps = utils.empty_map_table()

local sections = {
  b = { desc = "﬘ Buffer"},
  c = { desc = "  Copilot"},
  db = { desc = "  Dadbod UI" },
  dp = { desc = "  DAP" },
  f = { desc = "  Find" },
  g = { desc = "󰊢  Git" },
  l = { desc = "  LSP" },
  m = { desc = "🏗  Mason"},
  n = { desc = "󰟢  Null-Ls" },
  o = { desc = "  Obsidian" },
  p = { desc = "  Pomodoro" },
  r = { desc = "🧪 Tests" },
  s = { desc = "󱙝  Spectre" },
  v = { desc = "  Vim"}
}

-- Normal --
-- Better window navigation
maps.n["<C-h>"] = { "<C-w>h", desc = "Navigate to the left split" }
maps.n["<C-j>"] = { "<C-w>j", desc = "Navigate to the bottom split" }
maps.n["<C-k>"] = { "<C-w>k", desc = "Navigate to the top split" }
maps.n["<C-l>"] = { "<C-w>l", desc = "Navigate to the right split" }

-- Buffer commands
maps.n["<leader>b"] = sections.b
maps.n["<leader>bc"] = { "<cmd>bdelete<cr>", desc = "Close and delete buffer" }
maps.n["<leader>bd"] = { "<cmd>Bdelete<cr>", desc = "Delete buffer without closing the window" }

-- Clear highlights
maps.n["<leader>h"] = { "<cmd>nohlsearch<cr>", desc = "Clear highlights" }

-- Comment
maps.n["<leader>/"] = { "<cmd>lua require('Comment.api').toggle.linewise.current()<CR>", desc = "Toggle comment line" }
maps.v["<leader>/"] = { "<esc><cmd>lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<CR>", desc = "Toggle comment line" }

-- Find commands
maps.n["<leader>f"] = sections.f
maps.n["<leader>fb"] = { "<cmd>Telescope buffers<cr>", desc = "Find buffers" }
maps.n["<leader>ff"] = { "<cmd>Telescope find_files find_command=rg,--ignore,--hidden,--files <cr>", desc = "Find files" }
maps.n["<leader>fp"] = { "<cmd>Telescope projects<cr>", desc = "Find projects" }
maps.n["<leader>fw"] = { "<cmd>lua require('telescope').extensions.live_grep_args.live_grep_args()<cr>", desc = "Find words" }
maps.n["<leader>fz"] = { "<cmd>Telescope zoxide list<cr>", desc = "List directories" }
maps.n["<leader>ft"] = { "<cmd>Telescope toggleterm_manager<cr>", desc = "List Terminals" }

-- Navigate buffers
maps.n["<S-l>"] = { "<cmd>bnext<cr>", desc = "Next buffer" }
maps.n["<S-h>"] = { "<cmd>bprevious<cr>", desc = "Previous buffer" }

-- Quit
maps.n["<leader>q"] = { "<cmd>q<cr>", desc = "Quit" }

-- Resize with arrows
maps.n["<C-Up>"] = { "<cmd>resize -2<cr>", desc = "Shrink window horizontally" }
maps.n["<C-Down>"] = { "<cmd>resize +2<cr>", desc = "Increase window horizontally" }
maps.n["<C-Left>"] = { "<cmd>vertical -2<cr>", desc = "Shrink window vertically" }
maps.n["<C-Right>"] = { "<cmd>vertical +2<cr>", desc = "Increase window vertically" }

-- Write file
maps.n["<leader>w"] = { "<cmd>w!<cr>", desc = "Write to file" }
maps.n["<leader>wq"] = { "<cmd>wq!<cr>", desc = "Write to file and quit" }

-- Miscellaneous Vim commands
maps.n["<leader>v"] = sections.v
maps.n["<leader>va"] = { "<cmd>Alpha<cr>", desc = "Dashboard" }
maps.n["<leader>vl"] = { function() require("trouble").toggle("loclist") end, desc = "LocationList" }
maps.n["<leader>vm"] = { "<cmd>messages<cr>", desc = "Open messages" }
maps.n["<leader>vn"] = { "<cmd>Telescope notify<cr>", desc = "Open notifications history" }
maps.n["<leader>vp"] = { "<cmd>Telescope lazy<cr>", desc = "Plugin info" }
maps.n["<leader>vq"] = { function() require("trouble").toggle("quickfix") end, desc = "QuickFix" }
maps.n["<leader>vw"] = { "<cmd>Twilight<cr>", desc = "Toggle Twilight"}
maps.n["<leader>vz"] = { "<cmd>Lazy<cr>", desc = "Lazy Plugin Manager" }

-- Visual --
-- Better paste
maps.v["p"] = { "P", desc = "Better paste" }

-- Stay in indent mode
maps.v["<"] = { "<gv", desc = "Indent to the left" }
maps.v[">"] = { ">gv", desc = "Indent to the right" }

-- Plugins --
-- GitHub Copilot
maps.n["<leader>c"] = sections.c
maps.n["<leader>cd"] = { "<cmd>Copilot disable<cr>", desc = "Disable Copilot" }
maps.n["<leader>ce"] = { "<cmd>Copilot enable<cr>", desc = "Enable Copilot" }
maps.n["<leader>ch"] = { "<cmd>Copilot help<cr>", desc = "Display Copilot help page" }
maps.n["<leader>cp"] = { "<cmd>Copilot panel<cr>", desc = "Display up to 10 Copilot completions for current buffer."}
maps.n["<leader>csi"] = { "<cmd>Copilot signout<cr>", desc = "Signout of Copilot" }
maps.n["<leader>cst"] = { "<cmd>Copilot status<cr>", desc = "Display Copilot status" }

-- Dad Bod UI
maps.n["<leader>db"] = sections.db
maps.n["<leader>dbi"] = { "<cmd>DBUI<cr>", desc = "Open Dad Bod UI" }
maps.n["<leader>dba"] = { "<cmd>DBUIAddConnection", desc = "Add Dad Bod UI connection" }

-- NvimTree/Explorer
maps.n["<leader>e"] = { "<cmd>NvimTreeToggle<cr>", desc = "Toggle tree explorer" }

-- DAP
maps.n["<leader>dap"] = { desc = 'DAP' }
maps.n["<leader>dapb"] = { "<cmd>lua require'dap'.toggle_breakpoint()<cr>", desc = "Toggle breakpoint" }
maps.n["<leader>dapc"] = { "<cmd>lua require'dap'.continue()<cr>", desc = "Continue" }
maps.n["<leader>dapcm"] = { "<cmd>Telescope dap commands<cr>", desc = "Commands" }
maps.n["<leader>dapcn"] = { "<cmd>Telescope dap configurations<cr>", desc = "Config" }
maps.n["<leader>dapf"] = { "<cmd>Telescope dap frames<cr>", desc = "Frames" }
maps.n["<leader>dapi"] = { "<cmd>lua require'dap'.step_into()<cr>", desc = "Step into" }
maps.n["<leader>dapl"] = { "<cmd>Telescope dap list_breakpoints<cr>", desc = "List breakpoints" }
maps.n["<leader>daprl"] = { "<cmd>lua require'dap'.run_last()<cr>", desc = "Run last" }
maps.n["<leader>dapO"] = { "<cmd>lua require'dap'.step_out()<cr>", desc = "Step out" }
maps.n["<leader>dapo"] = { "<cmd>lua require'dap'.step_over()<cr>", desc = "Step over" }
maps.n["<leader>dapr"] = { "<cmd>lua require'dap'.repl.toggle()<cr>", desc = "Toggle REPL" }
maps.n["<leader>dapt"] = { "<cmd>lua require'dap'.terminate()<cr>", desc = "Terminate" }
maps.n["<leader>dapu"] = { "<cmd>lua require'dapui'.toggle()<cr>", desc = "Toggle Dap UI" }
maps.n["<leader>dapv"] = { "<cmd>Telescope dap variables<cr>", desc = "Variables" }

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
maps.n["<leader>lg"] = { desc = "GoTo" }
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
maps.n["<leader>lsh"] = { "<cmd>lua vim.lsp.buf.signature_help()<CR>", desc = "Signature help" }
maps.n["<leader>lsr"] = { function() require("trouble").toggle("lsp_references") end, desc = "Show References" }
maps.n["<leader>lsd"] = { function() require("trouble").toggle("lsp_definitions") end, desc = "Show Definitions" }
maps.n["<leader>lq"] = { "<cmd>lua vim.diagnostic.setloclist()<CR>", desc = "Setloclist" }

-- Mason
maps.n["<leader>m"] = sections.m
maps.n["<leader>mi"] = { "<cmd>Mason<cr>", desc = "Mason Control Panel" }
maps.n["<leader>ml"] = { "<cmd>MasonLog<cr>", desc = "Mason Log" }

-- None-Ls
maps.n["<leader>n"] = sections.n
maps.n["<leader>ni"] = { "<cmd>NullLsInfo<cr>", desc = "Null-Ls Info" }
maps.n["<leader>nl"] = { "<cmd>NullLsLog<cr>", desc = "Null-Ls Log"}

-- Obsidian.md
maps.n["<leader>o"] = sections.o
maps.n["<leader>ob"] = { "<cmd>ObsidianBacklinks<cr>", desc = "Open picker list of references to the current buffer." }
maps.n["<leader>ol"] = { "<cmd>ObsidianLinks<cr>", desc = "Open picker list of all links in the current buffer." }
maps.n["<leader>oo"] = { "<cmd>ObsidianOpen<cr>", desc = "Open current buffer in Obsidian." }
maps.n["<leader>on"] = { "<cmd>ObsidianNew<cr>", desc = "Open new note in Obsidian." }
maps.n["<leader>os"] = { "<cmd>ObsidianQuickSwitch<cr>", desc = "Switch to another note in Obsidian." }

-- pomo.nvim
maps.n["<leader>p"] = sections.p
maps.n["<leader>pb"] = { "<cmd>TimerStart 5m short_break<cr>", desc = "Start short break." }
maps.n["<leader>pl"] = { "<cmd>TimerStart 15m long_break<cr>", desc = "Start long break." }
maps.n["<leader>ps"] = { desc = "Stop timers." }
maps.n["<leader>psa"] = { "<cmd>TimerStop -1<cr>", desc = "Stop all timers." }
maps.n["<leader>psr"] = { "<cmd>TimerStop<cr>", desc = "Stop most recent timer." }
maps.n["<leader>pw"] = { "<cmd>TimerStart 25m work<cr>", desc = "Start work time." }

-- Trouble for None-Ls
maps.n["<leader>nt"] = { desc = 'Trouble Windows' }
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
