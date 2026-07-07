-- Tree-sitter parser registration

-- Register the dbt_sql_trino parser for sql.jinja filetype
-- Parser must be manually compiled and placed at ~/.config/nvim/parser/dbt_sql_trino.so
vim.treesitter.language.register("dbt_sql_trino", "sql.jinja")
