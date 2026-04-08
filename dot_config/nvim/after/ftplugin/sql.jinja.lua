if vim.g.vscode then
  return
end

vim.opt_local.commentstring = "{# %s #}"

vim.lsp.enable("jinja-lsp")
vim.lsp.enable("dbt-language-server")
