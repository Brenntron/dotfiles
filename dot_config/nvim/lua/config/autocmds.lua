-- Auto commands

local function augroup(name)
  return vim.api.nvim_create_augroup("bvim_" .. name, { clear = true })
end

-- Check if we need to reload the file when it changed
vim.api.nvim_create_autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
  group = augroup("checktime"),
  callback = function()
    if vim.o.buftype ~= "nofile" then
      vim.cmd("checktime")
    end
  end,
})

-- Enable treesitter highlight/indent via FileType (nvim-treesitter v1.x)
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("treesitter"),
  callback = function(ev)
    pcall(vim.treesitter.start, ev.buf)
  end,
})

-- Highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
  group = augroup("highlight_yank"),
  callback = function()
    vim.hl.on_yank()
  end,
})

-- Resize splits when window is resized
vim.api.nvim_create_autocmd("VimResized", {
  group = augroup("resize_splits"),
  callback = function()
    local current_tab = vim.fn.tabpagenr()
    vim.cmd("tabdo wincmd =")
    vim.cmd("tabnext " .. current_tab)
  end,
})

-- Go to last location when opening a buffer
vim.api.nvim_create_autocmd("BufReadPost", {
  group = augroup("last_loc"),
  callback = function(event)
    local exclude = { "gitcommit" }
    local buf = event.buf
    if vim.tbl_contains(exclude, vim.bo[buf].filetype) or vim.b[buf].bvim_last_loc then
      return
    end
    vim.b[buf].bvim_last_loc = true
    local mark = vim.api.nvim_buf_get_mark(buf, '"')
    local lcount = vim.api.nvim_buf_line_count(buf)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- Close some filetypes with <q>
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("close_with_q"),
  pattern = {
    "checkhealth",
    "gitsigns-blame",
    "help",
    "lspinfo",
    "nui",
    "notify",
    "qf",
    "snacks_win",
    "startuptime",
  },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<cr>", {
      buffer = event.buf,
      silent = true,
      desc = "Quit buffer",
    })
  end,
})

-- Make man pages unlisted
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("man_unlisted"),
  pattern = { "man" },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
  end,
})

-- Wrap and spell check in text filetypes
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("wrap_spell"),
  pattern = { "text", "plaintex", "typst", "gitcommit", "markdown" },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.spell = true
  end,
})

-- Fix conceallevel for json files
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("json_conceal"),
  pattern = { "json", "jsonc", "json5" },
  callback = function()
    vim.opt_local.conceallevel = 0
  end,
})

-- Auto create dir when saving a file
vim.api.nvim_create_autocmd("BufWritePre", {
  group = augroup("auto_create_dir"),
  callback = function(event)
    if event.match:match("^%w%w+:[\\/][\\/]") then
      return
    end
    local file = vim.uv.fs_realpath(event.match) or event.match
    vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
  end,
})

-- <esc><esc> to enter normal mode in terminal buffers
-- (single <esc> stays available for terminal apps)
vim.api.nvim_create_autocmd("TermOpen", {
  group = vim.api.nvim_create_augroup("bvim_term_esc", { clear = true }),
  pattern = "*",
  callback = function()
    vim.keymap.set("t", "<esc><esc>", [[<C-\><C-n>]], { buffer = 0, silent = true })
  end,
})

-- Highlight raw ANSI termcodes for use as a scrollback pager.
vim.api.nvim_create_user_command('TermH1', function()
  vim.api.nvim_open_term(0, {})
end, { desc = 'Highlights ANSI termcodes in curbuf' })

-- Buffer-local setup for dbt models (sql.jinja). Lives here instead of
-- after/ftplugin/ because dotted filetypes source per-component ftplugins
-- (sql.lua, jinja.lua) — a file named sql.jinja.lua is never sourced.
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("dbt_ftplugin"),
  pattern = "sql.jinja",
  callback = function(event)
    if vim.g.vscode then
      return
    end

    vim.bo[event.buf].commentstring = "{# %s #}"

    -- dbt-language-server is enabled at startup in lua/plugins/lsp.lua, not
    -- here: vim.lsp.enable() registers a FileType autocmd to autostart future
    -- matching buffers, and calling it from inside this same FileType dispatch
    -- is too late to catch the buffer that triggered it.

    local wk = require("which-key")

    wk.add({
      { "<leader>D", group = "dbt", icon = " ", buffer = event.buf },
      { "<leader>Dc", "<cmd>DbtCompile<cr>", desc = "Compile", buffer = event.buf },
      { "<leader>Dr", "<cmd>DbtRun<cr>", desc = "Run", buffer = event.buf },
      { "<leader>Db", "<cmd>DbtBuild<cr>", desc = "Build", buffer = event.buf },
      { "<leader>DB", "<cmd>DbtBuildSelect<cr>", desc = "Build (scope: up/down/both)", buffer = event.buf },
      { "<leader>DR", "<cmd>DbtRunFull<cr>", desc = "Run (full refresh)", buffer = event.buf },
      { "<leader>Dt", "<cmd>DbtTest<cr>", desc = "Test", buffer = event.buf },
      { "<leader>Dy", "<cmd>DbtModelYaml<cr>", desc = "Model YAML", buffer = event.buf },
      { "<leader>Dd", "<cmd>DbtGoToDefinition<cr>", desc = "Go to definition", buffer = event.buf },
      { "<leader>Du", "<cmd>DbtListUpstreamModels<cr>", desc = "Upstream models", buffer = event.buf },
      { "<leader>Ds", "<cmd>DbtListDownstreamModels<cr>", desc = "Downstream models", buffer = event.buf },
      { "<leader>DC", "<cmd>DbtCompiledPreview<cr>", desc = "Compiled SQL preview", buffer = event.buf },
      { "<leader>Dl", "<cmd>DbtLineage<cr>", desc = "Lineage graph", buffer = event.buf },
      { "<leader>De", "<cmd>DbtRerunLast<cr>", desc = "Re-run last command", buffer = event.buf },
      { "<leader>Df", "<cmd>DbtRunDefer<cr>", desc = "Run (defer to prod)", buffer = event.buf },
      { "<leader>Dg", "<cmd>DbtDiagnosticsRefresh<cr>", desc = "Refresh diagnostics", buffer = event.buf },
      { "<leader>Dp", "<cmd>DbtDeps<cr>", desc = "Deps", buffer = event.buf },
      { "<leader>Dh", "<cmd>DbtSeed<cr>", desc = "Seed", buffer = event.buf },
      { "<leader>Dn", "<cmd>DbtSnapshot<cr>", desc = "Snapshot", buffer = event.buf },
      { "<leader>Dm", "<cmd>DbtLogsTail<cr>", desc = "Logs (tail)", buffer = event.buf },
    }, { mode = "n" })
  end,
})

-- Refresh dbt ref/source diagnostics on save/read (manifest-backed, U8).
vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost" }, {
  group = augroup("dbt_diagnostics"),
  pattern = "*.sql",
  callback = function(event)
    if vim.bo[event.buf].filetype == "sql.jinja" then
      require("dbt-nvim.diagnostics").refresh(event.buf)
    end
  end,
})

-- Navigate between Claude terminal and editor windows in terminal mode
vim.api.nvim_create_autocmd("TermOpen", {
  group = vim.api.nvim_create_augroup("bvim_claudecode", { clear = true }),
  pattern = "*",
  callback = function()
    local opts = { buffer = 0, silent = true }
    vim.keymap.set("t", "<C-h>", [[<C-\><C-n><C-w>h]], opts)
    vim.keymap.set("t", "<C-j>", [[<C-\><C-n><C-w>j]], opts)
    vim.keymap.set("t", "<C-k>", [[<C-\><C-n><C-w>k]], opts)
    vim.keymap.set("t", "<C-l>", [[<C-\><C-n><C-w>l]], opts)
  end,
})
