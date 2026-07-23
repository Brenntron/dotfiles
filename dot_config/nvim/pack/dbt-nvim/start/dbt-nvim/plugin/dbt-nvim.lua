if vim.g.loaded_dbt_nvim then
  return
end
vim.g.loaded_dbt_nvim = true

require("dbt-nvim").setup()
