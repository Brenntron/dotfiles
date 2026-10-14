-- Linting: nvim-lint

local lint = require("lint")
local sqlfluff = require("config.sqlfluff")

-- Custom sqlfluff linter for dbt projects
local sqlfluff_linter = lint.linters.sqlfluff
if sqlfluff_linter then
  lint.linters.sqlfluff_dbt = vim.tbl_deep_extend("force", sqlfluff_linter, {
    cmd = function()
      return sqlfluff.command(vim.api.nvim_buf_get_name(0))
    end,
    stdin = false,
    args = { "lint", "--format=json" },
    append_fname = true,
  })
end

-- Linters by filetype
lint.linters_by_ft = {
  ["*"] = { "snyk_ls" },
  go = { "golangcilint" },
  javascript = { "eslint" },
  markdown = { "markdownlint-cli2" },
  python = { "ruff" },
  ruby = { "rubocop" },
  sh = { "shellcheck" },
  sql = { "sqlfluff" },
  ["sql.jinja"] = { "sqlfluff_dbt" },
  typescript = { "eslint" },
  yaml = { "yamllint" },
}

-- Lint on save and insert leave
vim.api.nvim_create_autocmd({ "BufWritePost", "InsertLeave", "BufReadPost" }, {
  group = vim.api.nvim_create_augroup("bvim_lint", { clear = true }),
  callback = function(args)
    local project_root = sqlfluff.project_root(vim.api.nvim_buf_get_name(args.buf))
    lint.try_lint(nil, project_root and { cwd = project_root } or nil)
  end,
})
