-- Linting: nvim-lint

local lint = require("lint")

-- Custom sqlfluff linter for dbt projects
local sqlfluff_linter = lint.linters.sqlfluff
if sqlfluff_linter then
  local function get_sqlfluff_cmd()
    local cwd = vim.fn.getcwd()
    local venv_sqlfluff = cwd .. "/.venv/bin/sqlfluff"
    if vim.fn.executable(venv_sqlfluff) == 1 then
      return venv_sqlfluff
    end
    return "sqlfluff"
  end

  lint.linters.sqlfluff_dbt = vim.tbl_deep_extend("force", sqlfluff_linter, {
    cmd = get_sqlfluff_cmd(),
    stdin = false,
    args = { "lint", "--format=json" },
    append_fname = true,
  })
end

-- Linters by filetype
lint.linters_by_ft = {
  javascript = { "eslint_d" },
  typescript = { "eslint_d" },
  python = { "black" },
  markdown = { "markdownlint-cli2" },
  ruby = { "rubocop" },
  ["sql.jinja"] = { "sqlfluff_dbt" },
  sql = { "sqlfluff" },
}

-- Lint on save and insert leave
vim.api.nvim_create_autocmd({ "BufWritePost", "InsertLeave", "BufReadPost" }, {
  group = vim.api.nvim_create_augroup("bvim_lint", { clear = true }),
  callback = function()
    lint.try_lint()
  end,
})
