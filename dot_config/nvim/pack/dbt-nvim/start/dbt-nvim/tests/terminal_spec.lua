-- Specs for the dbt-nvim floating-terminal host (U1).
-- Stubs snacks.terminal to capture the wrapper's calls without opening windows.

local function load_with_stub(stub)
  package.loaded["snacks"] = { terminal = stub }
  package.loaded["dbt-nvim.terminal"] = nil
  package.loaded["dbt-nvim.util"] = nil
  local terminal = require("dbt-nvim.terminal")
  return terminal
end

describe("dbt-nvim.terminal", function()
  local calls

  before_each(function()
    calls = {}
  end)

  after_each(function()
    package.loaded["snacks"] = nil
    package.loaded["dbt-nvim.terminal"] = nil
  end)

  it("opens a floating terminal running the command", function()
    local terminal = load_with_stub({
      open = function(cmd, opts)
        table.insert(calls, { cmd = cmd, opts = opts })
      end,
    })

    terminal.open({ "echo", "hi" }, { cwd = "/tmp/proj" })

    assert.equals(1, #calls)
    assert.same({ "echo", "hi" }, calls[1].cmd)
    assert.equals("/tmp/proj", calls[1].opts.cwd)
    assert.equals("float", calls[1].opts.win.position)
  end)

  it("defaults command output to non-interactive (persistent, scrollable)", function()
    local terminal = load_with_stub({
      open = function(cmd, opts)
        table.insert(calls, { cmd = cmd, opts = opts })
      end,
    })

    terminal.open({ "dbt", "run" }, { cwd = "/tmp/proj" })
    assert.equals(false, calls[1].opts.interactive)
  end)

  it("passes interactive=true through for TUIs", function()
    local terminal = load_with_stub({
      open = function(cmd, opts)
        table.insert(calls, { cmd = cmd, opts = opts })
      end,
    })

    terminal.open({ "dbt-lineage", "view", "m" }, { cwd = "/tmp/proj", interactive = true })
    assert.equals(true, calls[1].opts.interactive)
  end)

  it("re-runs the last remembered command", function()
    local terminal = load_with_stub({
      open = function(cmd, opts)
        table.insert(calls, { cmd = cmd, opts = opts })
      end,
    })

    terminal.open({ "dbt", "build" }, { cwd = "/tmp/proj" })
    terminal.rerun()

    assert.equals(2, #calls)
    assert.same({ "dbt", "build" }, calls[2].cmd)
    assert.equals("/tmp/proj", calls[2].opts.cwd)
  end)

  it("warns and does not open when nothing has run yet", function()
    local warned = {}
    local terminal = load_with_stub({
      open = function(cmd, opts)
        table.insert(calls, { cmd = cmd, opts = opts })
      end,
    })
    -- Fresh util module: swap notify to capture.
    require("dbt-nvim.util").notify = function(level, msg)
      table.insert(warned, { level = level, msg = msg })
    end

    terminal.rerun()

    assert.equals(0, #calls)
    assert.equals(1, #warned)
    assert.equals("WARN", warned[1].level)
  end)

  it("does not remember commands flagged remember=false", function()
    local terminal = load_with_stub({
      open = function(cmd, opts)
        table.insert(calls, { cmd = cmd, opts = opts })
      end,
    })
    require("dbt-nvim.util").notify = function() end

    terminal.open({ "dbt", "compile" }, { cwd = "/tmp/proj", remember = false })
    terminal.rerun()

    -- Only the initial open ran; rerun found nothing to repeat.
    assert.equals(1, #calls)
  end)
end)
