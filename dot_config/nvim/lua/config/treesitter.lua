-- Tree-sitter parser registration

-- Register the dbt_sql parser for sql.jinja filetype
-- Parser must be manually compiled and placed at ~/.config/nvim/parser/dbt_sql.so
vim.treesitter.language.register("dbt_sql", "sql.jinja")
