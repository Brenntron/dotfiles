local wk = require("which-key")

-- Python
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
  { "<leader>PdC", "<cmd>DbtCompiledPreview<cr>", desc = "Compiled SQL preview" },
  { "<leader>Pdl", "<cmd>DbtLineage<cr>", desc = "Lineage graph" },
  { "<leader>Pde", "<cmd>DbtRerunLast<cr>", desc = "Re-run last command" },

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
