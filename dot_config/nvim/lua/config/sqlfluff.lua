local M = {}

local root_markers = { ".sqlfluff", "dbt_project.yml" }

---@param path string
---@return string|nil
function M.project_root(path)
  local directory = vim.fn.isdirectory(path) == 1 and path or vim.fs.dirname(path)
  return vim.fs.root(directory, root_markers)
end

---@param path string
---@return string
function M.command(path)
  local project_root = M.project_root(path)
  if not project_root then
    return "sqlfluff"
  end

  local result = vim.system({ "git", "rev-parse", "--path-format=absolute", "--git-common-dir" }, {
    cwd = project_root,
    text = true,
  }):wait()
  if result.code ~= 0 then
    return "sqlfluff"
  end

  local primary_checkout = vim.fs.dirname(vim.trim(result.stdout))
  local sqlfluff = primary_checkout .. "/.venv/bin/sqlfluff"
  if vim.fn.executable(sqlfluff) == 1 then
    return sqlfluff
  end

  return "sqlfluff"
end

return M
