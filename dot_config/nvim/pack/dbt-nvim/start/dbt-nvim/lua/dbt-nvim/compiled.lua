local util = require("dbt-nvim.util")

local uv = vim.uv or vim.loop

local M = {}

local function join(root, rel)
  if vim.fs and vim.fs.joinpath then
    return vim.fs.normalize(vim.fs.joinpath(root, rel))
  end
  return root .. "/" .. rel
end

local function read_file(path)
  local fd = io.open(path, "r")
  if not fd then
    return nil
  end
  local content = fd:read("*a")
  fd:close()
  return content
end

-- Look up the current model in the manifest and return its package_name and
-- original_file_path, matching by name. Returns nil, err on failure.
local function find_model(root, model_name)
  local manifest_path = join(root, "target/manifest.json")
  if uv and not uv.fs_stat(manifest_path) then
    return nil, "dbt manifest not found. Run dbt compile to generate it."
  end
  local content = read_file(manifest_path)
  if not content then
    return nil, "Unable to read dbt manifest at " .. manifest_path
  end
  local ok, manifest = pcall(vim.fn.json_decode, content)
  if not ok then
    return nil, "Failed to parse dbt manifest.json"
  end
  for _, node in pairs(manifest.nodes or {}) do
    if node.resource_type == "model" and node.name == model_name then
      return {
        package_name = node.package_name,
        original_file_path = node.original_file_path,
        compiled_path = node.compiled_path,
      }
    end
  end
  return nil, "Model '" .. model_name .. "' not found in manifest."
end

-- Resolve the compiled SQL artifact path for a model.
-- dbt writes it to target/compiled/<package_name>/<original_file_path>; the
-- manifest's compiled_path is preferred when populated.
local function compiled_path(root, model)
  if model.compiled_path and model.compiled_path ~= vim.NIL then
    return join(root, model.compiled_path)
  end
  return join(root, join("target/compiled", join(model.package_name, model.original_file_path)))
end

-- Open the compiled (Jinja-expanded) SQL for the model under cursor in a
-- read-only scratch buffer.
function M.preview()
  local root = util.get_project_root()
  if not root then
    util.notify("WARN", "Not inside a dbt project (missing dbt_project.yml).")
    return false
  end
  local model_name = util.get_model_name()
  if not model_name then
    util.notify("WARN", "Current buffer is not a dbt model (.sql) file.")
    return false
  end

  local model, err = find_model(root, model_name)
  if not model then
    util.notify("WARN", err)
    return false
  end

  local path = compiled_path(root, model)
  if vim.fn.filereadable(path) == 0 then
    util.notify("WARN", "No compiled SQL for '" .. model_name .. "'. Run :DbtCompile first.")
    return false
  end

  local content = read_file(path)
  if not content then
    util.notify("WARN", "Unable to read compiled SQL at " .. path)
    return false
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(content, "\n", { plain = true }))
  vim.api.nvim_buf_set_name(buf, "dbt://compiled/" .. model_name .. ".sql")
  vim.api.nvim_set_option_value("filetype", "sql", { buf = buf })
  vim.api.nvim_set_option_value("buftype", "nofile", { buf = buf })
  vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
  vim.api.nvim_buf_set_keymap(buf, "n", "q", "<cmd>bdelete!<cr>", { noremap = true, silent = true })

  vim.cmd("belowright split")
  vim.api.nvim_win_set_buf(0, buf)
  return true
end

return M
