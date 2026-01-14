return {
  cmd = { "dbt-language-server" },
  filetypes = { "sql", "yaml" },
  root_dir = require'lspconfig'.util.root_pattern("dbt_project.yml"),
}
