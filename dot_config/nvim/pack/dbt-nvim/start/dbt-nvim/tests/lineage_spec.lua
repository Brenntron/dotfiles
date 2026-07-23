-- Specs for the dbt-lineage launcher (U4).

local function write(path, content)
  vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
  local fd = assert(io.open(path, "w"))
  fd:write(content)
  fd:close()
end

local function make_project()
  local root = vim.fn.tempname()
  write(root .. "/dbt_project.yml", "name: acme\n")
  write(root .. "/models/staging/stg_orders.sql", "select 1\n")
  return root
end

local calls, warned
local function load_lineage(executable)
  package.loaded["dbt-nvim.util"] = nil
  package.loaded["dbt-nvim.terminal"] = nil
  package.loaded["dbt-nvim.lineage"] = nil

  calls, warned = {}, {}
  package.loaded["dbt-nvim.terminal"] = {
    open = function(cmd, opts)
      table.insert(calls, { cmd = cmd, opts = opts })
    end,
  }
  local util = require("dbt-nvim.util")
  util.notify = function(level, msg)
    table.insert(warned, { level = level, msg = msg })
  end
  -- Stub executable detection so tests don't depend on a real install.
  local real_executable = vim.fn.executable
  vim.fn.executable = function(name)
    if name == "dbt-lineage" then
      return executable and 1 or 0
    end
    return real_executable(name)
  end
  return require("dbt-nvim.lineage")
end

describe("dbt-nvim.lineage", function()
  after_each(function()
    pcall(vim.cmd, "bufdo bdelete!")
    package.loaded["dbt-nvim.lineage"] = nil
    package.loaded["dbt-nvim.terminal"] = nil
    package.loaded["dbt-nvim.util"] = nil
  end)

  it("builds `dbt-lineage view <model> --project-dir <root>`", function()
    local lineage = load_lineage(true)
    assert.same(
      { "dbt-lineage", "view", "stg_orders", "--project-dir", "/proj" },
      lineage.build_command("stg_orders", "/proj")
    )
  end)

  it("launches the TUI interactively for the model under cursor", function()
    local root = make_project()
    local lineage = load_lineage(true)
    vim.cmd("edit " .. root .. "/models/staging/stg_orders.sql")

    assert.is_true(lineage.open())
    assert.equals(1, #calls)
    -- get_project_root resolves symlinks (macOS /var -> /private/var), so compare
    -- against the resolved root the launcher actually used, not the raw tempname.
    local used_root = calls[1].opts.cwd
    assert.same({ "dbt-lineage", "view", "stg_orders", "--project-dir", used_root }, calls[1].cmd)
    assert.is_true(calls[1].opts.interactive)
    assert.matches("stg_orders", root .. "/models/staging/stg_orders.sql")
  end)

  it("warns and does not launch when dbt-lineage is absent", function()
    local root = make_project()
    local lineage = load_lineage(false)
    vim.cmd("edit " .. root .. "/models/staging/stg_orders.sql")

    assert.is_false(lineage.open())
    assert.equals(0, #calls)
    assert.matches("PATH", warned[1].msg)
  end)

  it("warns and does not launch from a non-model buffer", function()
    local lineage = load_lineage(true)
    vim.cmd("enew")
    vim.cmd("file /tmp/scratch.md")

    assert.is_false(lineage.open())
    assert.equals(0, #calls)
  end)
end)
