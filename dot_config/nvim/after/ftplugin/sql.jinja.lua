if vim.g.vscode then
  return
end

vim.opt_local.commentstring = "{# %s #}"

vim.lsp.enable("dbt-language-server")

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
}, { mode = "n" })
