if vim.g.vscode then
  return
end

vim.lsp.enable('jinja-lsp')
vim.lsp.enable('dbt-language-server')
