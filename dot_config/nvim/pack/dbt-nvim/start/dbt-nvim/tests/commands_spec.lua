-- Specs for dbt command routing through the floating-terminal host (U2).
-- Stubs dbt-nvim.terminal to capture the command arrays the runners build.

local function fresh(model_name)
  package.loaded["dbt-nvim.util"] = nil
  package.loaded["dbt-nvim.terminal"] = nil
  package.loaded["dbt-nvim"] = nil
  package.loaded["snacks"] = { pick = function() end }

  local calls = {}
  package.loaded["dbt-nvim.terminal"] = {
    open = function(cmd, opts)
      table.insert(calls, { cmd = cmd, opts = opts })
    end,
    rerun = function()
      table.insert(calls, { rerun = true })
    end,
  }

  local D = require("dbt-nvim")
  -- Override model-name resolution so tests don't depend on a real buffer.
  D.get_model_name = function()
    return model_name
  end
  return D, calls
end

local function write(path, content)
  vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
  local fd = assert(io.open(path, "w"))
  fd:write(content)
  fd:close()
end

describe("dbt-nvim command routing", function()
  after_each(function()
    package.loaded["snacks"] = nil
    package.loaded["dbt-nvim.terminal"] = nil
    package.loaded["dbt-nvim"] = nil
  end)

  it("DbtRun builds `dbt run -s <model>` and opens the terminal", function()
    local D, calls = fresh("stg_orders")
    D.run()
    assert.equals(1, #calls)
    assert.same({ "dbt", "run", "-s", "stg_orders" }, calls[1].cmd)
  end)

  it("DbtRunFull inserts --full-refresh before the selector", function()
    local D, calls = fresh("stg_orders")
    D.run_full()
    assert.same({ "dbt", "run", "--full-refresh", "-s", "stg_orders" }, calls[1].cmd)
  end)

  it("DbtBuild and DbtTest build their respective commands", function()
    local D, calls = fresh("stg_orders")
    D.build()
    D.test()
    assert.same({ "dbt", "build", "-s", "stg_orders" }, calls[1].cmd)
    assert.same({ "dbt", "test", "-s", "stg_orders" }, calls[2].cmd)
  end)

  it("model_yaml builds the generate_model_yaml run-operation", function()
    local D, calls = fresh("stg_orders")
    D.model_yaml()
    assert.same({
      "dbt",
      "run-operation",
      "generate_model_yaml",
      "--args",
      '{"model_names": ["stg_orders"]}',
    }, calls[1].cmd)
  end)

  it("does not open a terminal when there is no model name", function()
    local D, calls = fresh(nil)
    D.run()
    D.model_yaml()
    assert.equals(0, #calls)
  end)

  describe("DbtRunDefer", function()
    local prev_state_path

    before_each(function()
      prev_state_path = vim.g.dbt_defer_state_path
    end)

    after_each(function()
      vim.g.dbt_defer_state_path = prev_state_path
    end)

    it("builds `--defer --state <path>` before the selector when configured", function()
      local root = vim.fn.tempname()
      vim.fn.mkdir(root .. "/state", "p")
      vim.g.dbt_defer_state_path = root .. "/state"

      local D, calls = fresh("stg_orders")
      D.run_defer()

      assert.equals(1, #calls)
      assert.same({ "dbt", "run", "--defer", "--state", root .. "/state", "-s", "stg_orders" }, calls[1].cmd)
    end)

    it("notifies and does not launch when the configured state path does not exist", function()
      vim.g.dbt_defer_state_path = "/tmp/does-not-exist-dbt-state"

      local D, calls = fresh("stg_orders")
      local prev_notify = vim.notify
      local warned = {}
      vim.notify = function(msg, level)
        table.insert(warned, { level = level, msg = msg })
      end

      D.run_defer()

      vim.notify = prev_notify
      assert.equals(0, #calls)
      assert.equals(1, #warned)
    end)

    it("does not build a malformed command when unset and the prompt is cancelled", function()
      vim.g.dbt_defer_state_path = nil
      local prev_input = vim.fn.input
      vim.fn.input = function()
        return ""
      end

      local D, calls = fresh("stg_orders")
      D.run_defer()

      vim.fn.input = prev_input
      assert.equals(0, #calls)
    end)
  end)

  describe("U13 dev-ex commands", function()
    it("DbtDeps builds `dbt deps`", function()
      local D, calls = fresh(nil)
      require("dbt-nvim.terminal").open({ "dbt", "deps" })
      assert.same({ "dbt", "deps" }, calls[1].cmd)
      assert.is_function(D.logs_tail) -- sanity: module loaded
    end)

    it("DbtSeed builds `dbt seed` project-wide with no model buffer", function()
      local D, calls = fresh(nil)
      D.seed()
      assert.same({ "dbt", "seed" }, calls[1].cmd)
    end)

    it("DbtSeed appends the selector when editing a resolvable model", function()
      local D, calls = fresh("stg_orders")
      D.seed()
      assert.same({ "dbt", "seed", "-s", "stg_orders" }, calls[1].cmd)
    end)

    it("DbtLogsTail builds a `tail -F` command with the resolved log path", function()
      local root = vim.fn.tempname()
      write(root .. "/dbt_project.yml", "name: acme\n")
      write(root .. "/logs/dbt.log", "log line\n")
      local D, calls = fresh(nil)
      vim.cmd("edit " .. root .. "/models/staging/stg_orders.sql")

      D.logs_tail()

      assert.equals(1, #calls)
      assert.same({ "tail", "-F", root .. "/logs/dbt.log" }, calls[1].cmd)
      assert.same({ interactive = false }, calls[1].opts)
    end)

    it("DbtLogsTail respects a custom log-path: from dbt_project.yml", function()
      local root = vim.fn.tempname()
      write(root .. "/dbt_project.yml", "name: acme\nlog-path: \"custom_logs\"\n")
      write(root .. "/custom_logs/dbt.log", "log line\n")
      local D, calls = fresh(nil)
      vim.cmd("edit " .. root .. "/models/staging/stg_orders.sql")

      D.logs_tail()

      assert.same({ "tail", "-F", root .. "/custom_logs/dbt.log" }, calls[1].cmd)
    end)

    it("DbtLogsTail notifies pointing at the expected location when missing", function()
      local root = vim.fn.tempname()
      write(root .. "/dbt_project.yml", "name: acme\n")
      local D, calls = fresh(nil)
      vim.cmd("edit " .. root .. "/models/staging/stg_orders.sql")
      local warned = {}
      local prev_notify = vim.notify
      vim.notify = function(msg, level)
        table.insert(warned, { level = level, msg = msg })
      end

      D.logs_tail()

      vim.notify = prev_notify
      assert.equals(0, #calls)
      assert.equals(1, #warned)
      assert.matches("dbt%.log", warned[1].msg)
    end)
  end)
end)
