-- Formatting: conform.nvim

require("conform").setup({
  formatters_by_ft = {
    css = { "prettierd" },
    go = { "gofmt" },
    html = { "prettierd" },
    javascript = { "prettierd" },
    json = { "prettierd" },
    lua = { "stylua" },
    markdown = { "prettierd", "markdownlint-cli2" },
    python = { "ruff_format" },
    ruby = { "rubocop" },
    rust = { "rustfmt" },
    sql = { "sqlfluff" },
    ["sql.jinja"] = { "sqlfluff_dbt" },
    typescript = { "prettierd" },
    yaml = { "prettierd" },
  },
  format_on_save = function()
    if not vim.g.autoformat then
      return
    end
    return { timeout_ms = 3000, lsp_fallback = true }
  end,
  formatters = {
    sqlfluff_dbt = {
      command = function()
        local cwd = vim.fn.getcwd()
        local venv_path = cwd .. "/.venv/bin/sqlfluff"
        if vim.fn.filereadable(venv_path) == 1 then
          return venv_path
        end
        return "sqlfluff"
      end,
      args = { "fix", "$FILENAME" },
      stdin = false,
      require_cwd = true,
      timeout_ms = 100000,
    },
  },
})
