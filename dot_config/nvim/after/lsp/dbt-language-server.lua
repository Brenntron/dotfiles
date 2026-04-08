return {
  cmd = { "dbt-language-server" },
  filetypes = { "sql.jinja" },
  root_dir = function(fname)
    return vim.fs.root(fname, { "dbt_project.yml" })
  end,
}
