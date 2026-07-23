local util = require("dbt-nvim.util")
local terminal = require("dbt-nvim.terminal")

local M = {}

-- Build the `dbt-lineage view` command for a model within a project root.
-- Exposed for testing.
function M.build_command(model_name, root)
  return { "dbt-lineage", "view", model_name, "--project-dir", root }
end

-- Launch the dbt-lineage TUI for the model under cursor in the floating host.
-- The TUI is interactive and inherits $NVIM, enabling the open-in-parent
-- callback (see the dbt-lineage `e` binding).
function M.open()
  if vim.fn.executable("dbt-lineage") == 0 then
    util.notify(
      "WARN",
      "dbt-lineage not found on PATH. Install it: uv tool install /path/to/dbt-lineage --with graphviz"
    )
    return false
  end

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

  terminal.open(M.build_command(model_name, root), { cwd = root, interactive = true })
  return true
end

return M
