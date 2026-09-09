-- Formatting: conform.nvim

require("conform").setup({
  formatters_by_ft = {
    cs = { "csharpier" },
    css = { "prettier" },
    go = { "gofmt" },
    html = { "prettier" },
    javascript = { "prettier" },
    json = { "prettier" },
    lua = { "stylua" },
    markdown = { "prettier", "markdownlint-cli2" },
    odin = { "odinfmt" },
    python = { "ruff_format" },
    ruby = { "rubocop" },
    rust = { "rustfmt" },
    sql = { "sqlfluff" },
    ["sql.jinja"] = { "sqlfluff_dbt" },
    typescript = { "prettier" },
    yaml = { "prettier", "yamlfmt" },
    zig = { "zigfmt" },
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
