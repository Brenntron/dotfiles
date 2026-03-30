-- Key mappings

local map = vim.keymap.set

-- Better up/down (handle wrapped lines)
map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })
map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { desc = "Up", expr = true, silent = true })

-- Move lines
map("n", "<A-j>", "<cmd>execute 'move .+' . v:count1<cr>==", { desc = "Move Down" })
map("n", "<A-k>", "<cmd>execute 'move .-' . (v:count1 + 1)<cr>==", { desc = "Move Up" })
map("i", "<A-j>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move Down" })
map("i", "<A-k>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move Up" })
map("v", "<A-j>", ":<C-u>execute \"'<,'>move '>+\" . v:count1<cr>gv=gv", { desc = "Move Down" })
map("v", "<A-k>", ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>gv=gv", { desc = "Move Up" })

-- Window navigation
map("n", "<C-h>", "<C-w>h", { desc = "Go to Left Window", remap = true })
map("n", "<C-j>", "<C-w>j", { desc = "Go to Lower Window", remap = true })
map("n", "<C-k>", "<C-w>k", { desc = "Go to Upper Window", remap = true })
map("n", "<C-l>", "<C-w>l", { desc = "Go to Right Window", remap = true })

-- Resize windows
map("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase Window Height" })
map("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Decrease Window Height" })
map("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease Window Width" })
map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase Window Width" })

-- Buffers
map("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Prev Buffer" })
map("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Next Buffer" })
map("n", "[b", "<cmd>bprevious<cr>", { desc = "Prev Buffer" })
map("n", "]b", "<cmd>bnext<cr>", { desc = "Next Buffer" })
map("n", "<leader>bb", "<cmd>e #<cr>", { desc = "Switch to Other Buffer" })
map("n", "<leader>bd", function() Snacks.bufdelete() end, { desc = "Delete Buffer" })
map("n", "<leader>bo", function() Snacks.bufdelete.other() end, { desc = "Delete Other Buffers" })
map("n", "<leader>bD", "<cmd>:bd<cr>", { desc = "Delete Buffer and Window" })

-- Clear search
map({ "i", "n" }, "<esc>", "<cmd>noh<cr><esc>", { desc = "Escape and Clear hlsearch" })

-- Consistent search direction
map("n", "n", "'Nn'[v:searchforward].'zv'", { expr = true, desc = "Next Search Result" })
map("n", "N", "'nN'[v:searchforward].'zv'", { expr = true, desc = "Prev Search Result" })
map({ "x", "o" }, "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next Search Result" })
map({ "x", "o" }, "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev Search Result" })

-- Undo break-points in insert mode
map("i", ",", ",<c-g>u")
map("i", ".", ".<c-g>u")
map("i", ";", ";<c-g>u")

-- Save file
map({ "i", "x", "n", "s" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save File" })

-- Better indenting (stay in visual mode)
map("v", "<", "<gv")
map("v", ">", ">gv")

-- Add comment line below/above
map("n", "gco", "o<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>", { desc = "Add Comment Below" })
map("n", "gcO", "O<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>", { desc = "Add Comment Above" })

-- Diagnostics (Neovim 0.12 API)
map("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Line Diagnostics" })
map("n", "]d", function() vim.diagnostic.jump({ count = 1, float = true }) end, { desc = "Next Diagnostic" })
map("n", "[d", function() vim.diagnostic.jump({ count = -1, float = true }) end, { desc = "Prev Diagnostic" })
map("n", "]e", function() vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.ERROR }) end, { desc = "Next Error" })
map("n", "[e", function() vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.ERROR }) end, { desc = "Prev Error" })
map("n", "]w", function() vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.WARN }) end, { desc = "Next Warning" })
map("n", "[w", function() vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.WARN }) end, { desc = "Prev Warning" })

-- Trouble / Quickfix / Location list
map("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", { desc = "Diagnostics (Trouble)" })
map("n", "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", { desc = "Buffer Diagnostics (Trouble)" })
map("n", "<leader>xs", "<cmd>Trouble symbols toggle<cr>", { desc = "Symbols (Trouble)" })
map("n", "<leader>xr", "<cmd>Trouble lsp toggle<cr>", { desc = "LSP References (Trouble)" })
map("n", "<leader>xq", "<cmd>Trouble qflist toggle<cr>", { desc = "Quickfix List (Trouble)" })
map("n", "<leader>xl", "<cmd>Trouble loclist toggle<cr>", { desc = "Location List (Trouble)" })
map("n", "[q", vim.cmd.cprev, { desc = "Prev Quickfix" })
map("n", "]q", vim.cmd.cnext, { desc = "Next Quickfix" })

-- Windows
map("n", "<leader>-", "<C-W>s", { desc = "Split Below" })
map("n", "<leader>|", "<C-W>v", { desc = "Split Right" })
map("n", "<leader>wc", "<C-W>c", { desc = "Close Window" })
map("n", "<leader>wv", "<C-W>v", { desc = "Split Vertical" })
map("n", "<leader>ws", "<C-W>s", { desc = "Split Horizontal" })

-- Tabs
map("n", "<leader><tab><tab>", "<cmd>tabnew<cr>", { desc = "New Tab" })
map("n", "<leader><tab>d", "<cmd>tabclose<cr>", { desc = "Close Tab" })
map("n", "<leader><tab>]", "<cmd>tabnext<cr>", { desc = "Next Tab" })
map("n", "<leader><tab>[", "<cmd>tabprevious<cr>", { desc = "Prev Tab" })

-- Quit
map("n", "<leader>qq", "<cmd>qa<cr>", { desc = "Quit All" })

-- New file
map("n", "<leader>fn", "<cmd>enew<cr>", { desc = "New File" })

-- Explorer
map("n", "<leader>e", function() Snacks.explorer() end, { desc = "File Explorer" })

-- Formatting
map({ "n", "v" }, "<leader>cf", function()
  require("conform").format({ async = true, lsp_fallback = true })
end, { desc = "Format" })

-- File/Find (Snacks picker)
map("n", "<leader>fc", function() Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')}) end, { desc = "Find Files" })
map("n", "<leader>ff", function() Snacks.picker.files() end, { desc = "Find Files" })
map("n", "<leader>fg", function() Snacks.picker.grep() end, { desc = "Live Grep" })
map("n", "<leader>fb", function() Snacks.picker.buffers() end, { desc = "Buffers" })
map("n", "<leader>fr", function() Snacks.picker.recent() end, { desc = "Recent Files" })
map("n", "<leader><leader>", function() Snacks.picker.files() end, { desc = "Find Files" })
map("n", "<leader>/", function() Snacks.picker.grep() end, { desc = "Live Grep" })

-- Search (Snacks picker)
map("n", "<leader>ss", function() Snacks.picker.lsp_symbols() end, { desc = "Search Symbols" })
map("n", "<leader>sd", function() Snacks.picker.diagnostics() end, { desc = "Search Diagnostics" })
map("n", "<leader>sh", function() Snacks.picker.help() end, { desc = "Search Help" })
map("n", "<leader>sk", function() Snacks.picker.keymaps() end, { desc = "Search Keymaps" })
map("n", "<leader>sr", function() Snacks.picker.resume() end, { desc = "Resume Picker" })
map("n", "<leader>sc", pick_chezmoi, { desc = "Chezmoi" })
map("n", "<leader>sg", function() Snacks.picker.grep() end, { desc = "Grep" })
map({ "n", "x" }, "<leader>sw", function() Snacks.picker.grep_word() end, { desc = "Grep Word" })

-- Git (Snacks)
map("n", "<leader>gg", function() Snacks.lazygit() end, { desc = "Lazygit" })
map("n", "<leader>gG", function() Snacks.lazygit({ cwd = vim.fn.getcwd() }) end, { desc = "Lazygit (cwd)" })
map("n", "<leader>gb", function() Snacks.git.blame_line() end, { desc = "Git Blame Line" })
map("n", "<leader>gB", function() Snacks.gitbrowse() end, { desc = "Git Browse" })
map("n", "<leader>gl", function() Snacks.picker.git_log() end, { desc = "Git Log" })
map("n", "<leader>gf", function() Snacks.picker.git_log_file() end, { desc = "Git File History" })

-- LSP (supplements Neovim 0.12 built-in gd, gr, K, grn, gra, grr)
map("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Code Action" })
map("n", "<leader>cr", vim.lsp.buf.rename, { desc = "Rename" })
map("n", "<leader>cl", "<cmd>lsp<cr>", { desc = "LSP Info" })
map("n", "<leader>cm", "<cmd>Mason<cr>", { desc = "Mason" })

-- Terminal 
-- (Snacks)
map("n", "<leader>fF", function() Snacks.terminal() end, { desc = "Terminal (Root)" })
map("n", "<leader>fT", function() Snacks.terminal(nil, { cwd = vim.fn.getcwd() }) end, { desc = "Terminal (cwd)" })
map("n", "<c-/>", function() Snacks.terminal() end, { desc = "Terminal" })
map("t", "<c-/>", "<cmd>close<cr>", { desc = "Hide Terminal" })
-- (toggleterm)
map("n", "<c-\\>", "<cmd>ToggleTerm direction=float<cr>", { desc = "Float Terminal" })

-- Toggle options
map("n", "<leader>uw", function() vim.wo.wrap = not vim.wo.wrap end, { desc = "Toggle Wrap" })
map("n", "<leader>ul", function() vim.wo.number = not vim.wo.number end, { desc = "Toggle Line Numbers" })
map("n", "<leader>uL", function() vim.wo.relativenumber = not vim.wo.relativenumber end, { desc = "Toggle Relative Numbers" })
map("n", "<leader>us", function() vim.wo.spell = not vim.wo.spell end, { desc = "Toggle Spelling" })
map("n", "<leader>ud", function() vim.diagnostic.enable(not vim.diagnostic.is_enabled()) end, { desc = "Toggle Diagnostics" })
map("n", "<leader>uc", function()
  local cl = vim.wo.conceallevel
  vim.wo.conceallevel = cl > 0 and 0 or 2
end, { desc = "Toggle Conceallevel" })
map("n", "<leader>uh", function()
  vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
end, { desc = "Toggle Inlay Hints" })
map("n", "<leader>uT", function()
  if vim.b.ts_highlight then
    vim.treesitter.stop()
  else
    vim.treesitter.start()
  end
end, { desc = "Toggle Treesitter Highlight" })

-- Session (persistence.nvim)
map("n", "<leader>qs", function() require("persistence").load() end, { desc = "Restore Session" })
map("n", "<leader>qS", function() require("persistence").select() end, { desc = "Select Session" })
map("n", "<leader>ql", function() require("persistence").load({ last = true }) end, { desc = "Restore Last Session" })
map("n", "<leader>qd", function() require("persistence").stop() end, { desc = "Don't Save Current Session" })

-- Flash
map({ "n", "x", "o" }, "s", function() require("flash").jump() end, { desc = "Flash" })
map({ "n", "x", "o" }, "S", function() require("flash").treesitter() end, { desc = "Flash Treesitter" })
map("o", "r", function() require("flash").remote() end, { desc = "Remote Flash" })
map({ "o", "x" }, "R", function() require("flash").treesitter_search() end, { desc = "Treesitter Search" })
map("c", "<c-s>", function() require("flash").toggle() end, { desc = "Toggle Flash Search" })

-- Yanky
map({ "n", "x" }, "<leader>p", function() Snacks.picker.yanky() end, { desc = "Open Yank History" }) ---@diagnostic disable-line: undefined-field
map({ "n", "x" }, "y", "<Plug>(YankyYank)", { desc = "Yank Text" })
map({ "n", "x" }, "p", "<Plug>(YankyPutAfter)", { desc = "Put After Cursor" })
map({ "n", "x" }, "P", "<Plug>(YankyPutBefore)", { desc = "Put Before Cursor" })
map({ "n", "x" }, "gp", "<Plug>(YankyGPutAfter)", { desc = "Put After Selection" })
map({ "n", "x" }, "gP", "<Plug>(YankyGPutBefore)", { desc = "Put Before Selection" })
map("n", "[y", "<Plug>(YankyCycleForward)", { desc = "Cycle Forward Through Yank History" })
map("n", "]y", "<Plug>(YankyCycleBackward)", { desc = "Cycle Backward Through Yank History" })
map("n", "]p", "<Plug>(YankyPutIndentAfterLinewise)", { desc = "Put Indented After Cursor (Linewise)" })
map("n", "[p", "<Plug>(YankyPutIndentBeforeLinewise)", { desc = "Put Indented Before Cursor (Linewise)" })
map("n", "]P", "<Plug>(YankyPutIndentAfterLinewise)", { desc = "Put Indented After Cursor (Linewise)" })
map("n", "[P", "<Plug>(YankyPutIndentBeforeLinewise)", { desc = "Put Indented Before Cursor (Linewise)" })
map("n", ">p", "<Plug>(YankyPutIndentAfterShiftRight)", { desc = "Put and Indent Right" })
map("n", "<p", "<Plug>(YankyPutIndentAfterShiftLeft)", { desc = "Put and Indent Left" })
map("n", ">P", "<Plug>(YankyPutIndentBeforeShiftRight)", { desc = "Put Before and Indent Right" })
map("n", "<P", "<Plug>(YankyPutIndentBeforeShiftLeft)", { desc = "Put Before and Indent Left" })
map("n", "=p", "<Plug>(YankyPutAfterFilter)", { desc = "Put After Applying a Filter" })
map("n", "=P", "<Plug>(YankyPutBeforeFilter)", { desc = "Put Before Applying a Filter" })
map("n", "<c-p>", "<Plug>(YankyPreviousEntry)", { desc = "Prev Yank Entry" })
map("n", "<c-n>", "<Plug>(YankyNextEntry)", { desc = "Next Yank Entry" })

-- Undotree
map("n", "<leader>cu", function() require("undotree").toggle() end, { desc = "Undotree" })

-- AI (Claude Code)
local wk = require("which-key")
wk.add({
  { "<leader>a", group = "ai", icon = "󰚩 " },
})
map("n", "<leader>ac", "<cmd>ClaudeCode<cr>", { desc = "Toggle Claude Code" })
map("n", "<leader>af", "<cmd>ClaudeCodeFocus<cr>", { desc = "Focus Claude Code" })
map("n", "<leader>ar", "<cmd>ClaudeCode --resume<cr>", { desc = "Resume Claude Code" })
map("n", "<leader>aC", "<cmd>ClaudeCode --continue<cr>", { desc = "Continue Claude Code" })
map("n", "<leader>ab", "<cmd>ClaudeCodeAdd<cr>", { desc = "Add current buffer" })
map("n", "<leader>ao", "<cmd>ClaudeCodeOpen<cr>", { desc = "Open Claude Code" })
map("n", "<leader>ax", "<cmd>ClaudeCodeClose<cr>", { desc = "Close Claude Code" })
map("n", "<leader>as", "<cmd>ClaudeCodeStatus<cr>", { desc = "Claude Code Status" })
map("n", "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", { desc = "Select Model" })
map({ "v" }, "<leader>as", "<cmd>ClaudeCodeSend<cr>", { desc = "Send to Claude" })
map({ "n" }, "<leader>as", "<cmd>ClaudeCodeTreeAdd<cr>", { desc = "Add file" })
map("n", "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", { desc = "Accept Diff" })
map("n", "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", { desc = "Deny Diff" })

-- Python / dbt
wk.add({
  { "<leader>P", group = "Python", icon = " " },

  { "<leader>Pd", group = "dbt" },
  { "<leader>Pdc", "<cmd>DbtCompile<cr>", desc = "Compile" },
  { "<leader>Pdr", "<cmd>DbtRun<cr>", desc = "Run" },
  { "<leader>Pdb", "<cmd>DbtBuild<cr>", desc = "Build" },
  { "<leader>PdR", "<cmd>DbtRunFull<cr>", desc = "Run (full refresh)" },
  { "<leader>Pdt", "<cmd>DbtTest<cr>", desc = "Test" },
  { "<leader>Pdy", "<cmd>DbtModelYaml<cr>", desc = "Model YAML" },
  { "<leader>Pdd", "<cmd>DbtGoToDefinition<cr>", desc = "Go to definition" },
  { "<leader>Pdu", "<cmd>DbtListUpstreamModels<cr>", desc = "Upstream models" },
  { "<leader>Pds", "<cmd>DbtListDownstreamModels<cr>", desc = "Downstream models" },

  { "<leader>Pu", group = "uv" },
  { "<leader>Pur", "<cmd>UVRunFile<cr>", desc = "Run current file" },
  { "<leader>Pus", "<cmd>UVRunSelection<cr>", desc = "Run selected code" },
  { "<leader>Puf", "<cmd>UVRunFunction<cr>", desc = "Run specific function" },
  { "<leader>Pue", "<cmd>lua Snacks.picker.pick('uv_venv')<cr>", desc = "Environment management" },
  { "<leader>Pui", "<cmd>UVInit<cr>", desc = "Initialize UV project" },
  { "<leader>Pua", "<cmd>lua vim.ui.input({prompt = 'Enter package name: '}, function(input) if input and input ~= '' then require('uv').run_command('uv add ' .. input) end end)<cr>", desc = "Add package" },
  { "<leader>Pud", "<cmd>lua require('uv').remove_package()<cr>", desc = "Remove package" },
  { "<leader>Puc", "<cmd>lua require('uv').run_command('uv sync')<cr>", desc = "Sync packages" },
})

