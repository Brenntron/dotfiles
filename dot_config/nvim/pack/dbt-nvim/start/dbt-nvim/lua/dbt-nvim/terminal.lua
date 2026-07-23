local util = require("dbt-nvim.util")

local M = {}

-- The most recent command run through the host, for DbtRerunLast.
local last = nil

local function has_snacks()
  local ok, snacks = pcall(require, "snacks")
  if not ok then
    util.notify("ERROR", "snacks.nvim is required for the dbt floating terminal.")
    return nil
  end
  return snacks
end

-- Resolve the cwd for a command: the dbt project root when available, else nil
-- (Snacks falls back to the editor cwd).
local function resolve_cwd(opts)
  if opts and opts.cwd then
    return opts.cwd
  end
  return util.get_project_root()
end

-- Open a lazygit-style floating terminal running `cmd`.
-- opts:
--   cwd         explicit working directory (defaults to dbt project root)
--   interactive true for TUIs (input forwarding, auto-close), false for command
--               output (persistent, starts in normal mode so it is scrollable)
--   remember    when true, record the command for DbtRerunLast (default: true)
--   on_exit     optional fn(lines, exit_code) called with the terminal buffer's
--               captured output when the job exits (used by U9 to parse
--               compile/build errors into diagnostics without duplicating the
--               job-tracking snacks.terminal already does)
function M.open(cmd, opts)
  local snacks = has_snacks()
  if not snacks then
    return nil
  end
  opts = opts or {}

  if opts.remember ~= false then
    last = { cmd = cmd, opts = { cwd = opts.cwd, interactive = opts.interactive } }
  end

  local win = snacks.terminal.open(cmd, {
    cwd = resolve_cwd(opts),
    interactive = opts.interactive == true,
    win = { style = "terminal", position = "float" },
  })

  if win and opts.on_exit then
    win:on("TermClose", function()
      local exit_code = type(vim.v.event) == "table" and vim.v.event.status or 0
      local lines = vim.api.nvim_buf_is_valid(win.buf) and vim.api.nvim_buf_get_lines(win.buf, 0, -1, false) or {}
      opts.on_exit(lines, exit_code)
    end, { buf = true })
  end

  return win
end

-- Toggle a floating terminal for `cmd` (reuses the instance keyed by cmd+cwd).
function M.toggle(cmd, opts)
  local snacks = has_snacks()
  if not snacks then
    return nil
  end
  opts = opts or {}
  return snacks.terminal.toggle(cmd, {
    cwd = resolve_cwd(opts),
    interactive = opts.interactive == true,
    win = { style = "terminal", position = "float" },
  })
end

-- Re-run the most recent command opened through the host.
function M.rerun()
  if not last then
    util.notify("WARN", "No dbt command has been run yet.")
    return nil
  end
  return M.open(last.cmd, last.opts)
end

return M
