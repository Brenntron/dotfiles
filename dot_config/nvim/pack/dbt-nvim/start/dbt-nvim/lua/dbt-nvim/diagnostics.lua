local util = require("dbt-nvim.util")
local dbt = require("dbt-nvim")

local M = {}

local ns = vim.api.nvim_create_namespace("dbt-nvim/diagnostics")

-- Diagnostics are category-partitioned within the shared namespace so U8's
-- ref/source scan and U9's run-error publish don't clobber each other on
-- refresh. Each category owns a bufnr -> diagnostics[] slice, and every
-- publish re-flattens both slices before calling vim.diagnostic.set.
local by_buf = { ref = {}, run = {} }

local function publish(bufnr)
  local items = {}
  vim.list_extend(items, by_buf.ref[bufnr] or {})
  vim.list_extend(items, by_buf.run[bufnr] or {})
  vim.diagnostic.set(ns, bufnr, items)
end

-- Scan `bufnr` for ref()/source() calls that don't resolve against the
-- manifest index, publishing WARN diagnostics for each unresolved reference.
-- No-ops (clearing stale diagnostics) outside a dbt project or without a
-- readable manifest.
function M.refresh(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  by_buf.ref[bufnr] = {}

  local root = util.get_project_root(bufnr)
  if not root then
    publish(bufnr)
    return
  end

  local index, err = dbt.get_manifest_index(root)
  if not index then
    if err then
      util.notify("WARN", err)
    end
    publish(bufnr)
    return
  end

  local diags = {}
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  for lnum, line in ipairs(lines) do
    for ref in dbt.iter_references(line) do
      local target
      if ref.type == "model" then
        target = index.models[ref.full] or index.models[ref.key]
      else
        target = index.sources[ref.full]
      end
      if not target then
        table.insert(diags, {
          lnum = lnum - 1,
          col = ref.start_col - 1,
          end_col = ref.end_col,
          severity = vim.diagnostic.severity.WARN,
          source = "dbt-nvim",
          message = "Unresolved dbt reference: " .. ref.full,
        })
      end
    end
  end

  by_buf.ref[bufnr] = diags
  publish(bufnr)
end

-- dbt Core error banner, e.g.:
--   Compilation Error in model stg_orders (models/staging/stg_orders.sql)
-- The message is the first non-blank line that follows the banner.
local ERROR_BANNER_PATTERN = "^%s*(%a[%a ]*Error) in model [%w_]+ %(([^)]+)%)%s*$"

-- Best-effort parse of dbt Core terminal output into {path, message} error
-- entries. Returns an empty list (never nil) when nothing matches, so
-- unparseable output degrades to "publish nothing false" rather than erroring.
function M.parse_run_output(lines)
  local errors = {}
  local i = 1
  while i <= #lines do
    local err_type, path = lines[i]:match(ERROR_BANNER_PATTERN)
    if err_type and path then
      local message = nil
      for j = i + 1, #lines do
        local candidate = vim.trim(lines[j])
        if candidate ~= "" then
          message = candidate
          break
        end
      end
      table.insert(errors, { path = path, message = err_type .. ": " .. (message or "see terminal output") })
    end
    i = i + 1
  end
  return errors
end

-- Publish diagnostics parsed from a dbt command's terminal output for the
-- "run" category. Passing an empty list clears prior run-error diagnostics
-- for that buffer (e.g. after a clean compile).
function M.set_run_diagnostics(bufnr, diags)
  by_buf.run[bufnr] = diags
  publish(bufnr)
end

-- Handle a completed dbt job: parse its output, map each error to the
-- open buffer for its file (root-relative path from the manifest banner),
-- and publish. Errors naming a file that isn't open are dropped (documented
-- skip; terminal scrollback remains the source of truth for those).
function M.handle_run_output(root, lines)
  local errors = M.parse_run_output(lines)

  local touched = {}
  for _, err in ipairs(errors) do
    local absolute = vim.fs and vim.fs.joinpath and vim.fs.normalize(vim.fs.joinpath(root, err.path)) or (root .. "/" .. err.path)
    local bufnr = vim.fn.bufnr(absolute)
    if bufnr ~= -1 then
      touched[bufnr] = touched[bufnr] or {}
      table.insert(touched[bufnr], {
        lnum = 0,
        col = 0,
        severity = vim.diagnostic.severity.ERROR,
        source = "dbt-nvim",
        message = err.message,
      })
    end
  end

  -- Clear stale run-diagnostics on any buffer that previously had them but
  -- has none in this run (e.g. a subsequent clean compile).
  for bufnr in pairs(by_buf.run) do
    if not touched[bufnr] then
      touched[bufnr] = {}
    end
  end

  for bufnr, diags in pairs(touched) do
    M.set_run_diagnostics(bufnr, diags)
  end
end

return M
