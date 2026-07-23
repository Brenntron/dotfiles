local M = {}

function M.notify(level, msg)
  if vim.notify and vim.log and vim.log.levels then
    vim.notify(msg, vim.log.levels[level] or vim.log.levels.INFO)
  else
    print(msg)
  end
end

-- Locate the dbt project root (directory containing dbt_project.yml) for a buffer.
function M.get_project_root(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == "" then
    return nil
  end
  local dir = vim.fn.fnamemodify(name, ":p:h")
  local root
  if vim.fs and vim.fs.find then
    local found = vim.fs.find("dbt_project.yml", { upward = true, path = dir })
    if found and #found > 0 then
      root = vim.fn.fnamemodify(found[1], ":p:h")
    end
  end
  if not root then
    local project = vim.fn.findfile("dbt_project.yml", dir .. ";")
    if project ~= "" then
      root = vim.fn.fnamemodify(project, ":p:h")
    end
  end
  return root
end

-- Get the model name from the current buffer if it is a .sql file.
function M.get_model_name()
  local ext = vim.fn.expand("%:e")
  if ext ~= "sql" then
    return nil
  end
  return vim.fn.expand("%:t:r")
end

return M
