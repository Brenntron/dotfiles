if vim.g.vscode then
  return
end

vim.opt_local.commentstring = "{# %s #}"

-- dbt-language-server is enabled at startup in lua/plugins/lsp.lua, not
-- here: vim.lsp.enable() registers a FileType autocmd to autostart future
-- matching buffers, and calling it from inside this same FileType dispatch
-- (ftplugin) is too late to catch the buffer that triggered it.

local wk = require("which-key")

wk.add({
  { "<leader>D", group = "dbt", icon = " ", buffer = 0 },
  { "<leader>Dc", "<cmd>DbtCompile<cr>", desc = "Compile", buffer = 0 },
  { "<leader>Dr", "<cmd>DbtRun<cr>", desc = "Run", buffer = 0 },
  { "<leader>Db", "<cmd>DbtBuild<cr>", desc = "Build", buffer = 0 },
  { "<leader>DR", "<cmd>DbtRunFull<cr>", desc = "Run (full refresh)", buffer = 0 },
  { "<leader>Dt", "<cmd>DbtTest<cr>", desc = "Test", buffer = 0 },
  { "<leader>Dy", "<cmd>DbtModelYaml<cr>", desc = "Model YAML", buffer = 0 },
  { "<leader>Dd", "<cmd>DbtGoToDefinition<cr>", desc = "Go to definition", buffer = 0 },
  { "<leader>Du", "<cmd>DbtListUpstreamModels<cr>", desc = "Upstream models", buffer = 0 },
  { "<leader>Ds", "<cmd>DbtListDownstreamModels<cr>", desc = "Downstream models", buffer = 0 },
  { "<leader>DC", "<cmd>DbtCompiledPreview<cr>", desc = "Compiled SQL preview", buffer = 0 },
  { "<leader>Dl", "<cmd>DbtLineage<cr>", desc = "Lineage graph", buffer = 0 },
  { "<leader>De", "<cmd>DbtRerunLast<cr>", desc = "Re-run last command", buffer = 0 },
  { "<leader>Df", "<cmd>DbtRunDefer<cr>", desc = "Run (defer to prod)", buffer = 0 },
  { "<leader>Dg", "<cmd>DbtDiagnosticsRefresh<cr>", desc = "Refresh diagnostics", buffer = 0 },
  { "<leader>Dp", "<cmd>DbtDeps<cr>", desc = "Deps", buffer = 0 },
  { "<leader>Dh", "<cmd>DbtSeed<cr>", desc = "Seed", buffer = 0 },
  { "<leader>Dn", "<cmd>DbtSnapshot<cr>", desc = "Snapshot", buffer = 0 },
  { "<leader>Dm", "<cmd>DbtLogsTail<cr>", desc = "Logs (tail)", buffer = 0 },
}, { mode = "n" })
