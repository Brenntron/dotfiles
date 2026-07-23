-- Specs for manifest-backed ref/source diagnostics (U8).

local function write(path, content)
  vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
  local fd = assert(io.open(path, "w"))
  fd:write(content)
  fd:close()
end

local function make_project()
  local root = vim.fn.tempname()
  write(root .. "/dbt_project.yml", "name: acme\n")

  local manifest = {
    nodes = {
      ["model.acme.stg_orders"] = {
        resource_type = "model",
        name = "stg_orders",
        package_name = "acme",
        original_file_path = "models/staging/stg_orders.sql",
      },
    },
    sources = {
      ["source.acme.raw.orders"] = {
        source_name = "raw",
        name = "orders",
        original_file_path = "models/staging/_sources.yml",
      },
    },
  }
  write(root .. "/target/manifest.json", vim.fn.json_encode(manifest))
  return root
end

local function load_diagnostics()
  package.loaded["dbt-nvim.util"] = nil
  package.loaded["dbt-nvim"] = nil
  package.loaded["dbt-nvim.diagnostics"] = nil
  return require("dbt-nvim.diagnostics")
end

local function open_buffer(root, rel, content)
  local path = root .. "/" .. rel
  write(path, content)
  vim.cmd("edit " .. path)
  return vim.api.nvim_get_current_buf()
end

local ns = vim.api.nvim_create_namespace("dbt-nvim/diagnostics")

describe("dbt-nvim.diagnostics", function()
  after_each(function()
    pcall(vim.cmd, "bufdo bdelete!")
    package.loaded["dbt-nvim.diagnostics"] = nil
    package.loaded["dbt-nvim"] = nil
    package.loaded["dbt-nvim.util"] = nil
  end)

  it("produces no diagnostics for a resolved ref", function()
    local root = make_project()
    local diagnostics = load_diagnostics()
    local buf = open_buffer(root, "models/staging/stg_customers.sql", "select * from {{ ref('stg_orders') }}\n")

    diagnostics.refresh(buf)

    assert.equals(0, #vim.diagnostic.get(buf, { namespace = ns }))
  end)

  it("produces one WARN diagnostic for an unresolved ref", function()
    local root = make_project()
    local diagnostics = load_diagnostics()
    local buf = open_buffer(root, "models/staging/stg_customers.sql", "select * from {{ ref('does_not_exist') }}\n")

    diagnostics.refresh(buf)

    local diags = vim.diagnostic.get(buf, { namespace = ns })
    assert.equals(1, #diags)
    assert.equals(vim.diagnostic.severity.WARN, diags[1].severity)
  end)

  it("resolves source() and flags unresolved sources", function()
    local root = make_project()
    local diagnostics = load_diagnostics()
    local buf = open_buffer(
      root,
      "models/staging/stg_customers.sql",
      "select * from {{ source('raw', 'orders') }}\nselect * from {{ source('raw', 'missing') }}\n"
    )

    diagnostics.refresh(buf)

    local diags = vim.diagnostic.get(buf, { namespace = ns })
    assert.equals(1, #diags)
    assert.equals(1, diags[1].lnum)
  end)

  it("flags only the bad ref when multiple refs share a line", function()
    local root = make_project()
    local diagnostics = load_diagnostics()
    local buf = open_buffer(
      root,
      "models/staging/stg_customers.sql",
      "select * from {{ ref('stg_orders') }} join {{ ref('does_not_exist') }}\n"
    )

    diagnostics.refresh(buf)

    local diags = vim.diagnostic.get(buf, { namespace = ns })
    assert.equals(1, #diags)
    assert.is_true(diags[1].col > 0)
  end)

  it("clears diagnostics outside a dbt project", function()
    local diagnostics = load_diagnostics()
    vim.cmd("enew")
    vim.cmd("file /tmp/loose_model.sql")
    local buf = vim.api.nvim_get_current_buf()

    diagnostics.refresh(buf)

    assert.equals(0, #vim.diagnostic.get(buf, { namespace = ns }))
  end)

  it("clears diagnostics and notifies once when the manifest is missing", function()
    local root = vim.fn.tempname()
    write(root .. "/dbt_project.yml", "name: acme\n")
    local diagnostics = load_diagnostics()

    local util = require("dbt-nvim.util")
    local warned = {}
    util.notify = function(level, msg)
      table.insert(warned, { level = level, msg = msg })
    end

    local buf = open_buffer(root, "models/staging/stg_customers.sql", "select * from {{ ref('stg_orders') }}\n")

    diagnostics.refresh(buf)

    assert.equals(0, #vim.diagnostic.get(buf, { namespace = ns }))
    assert.equals(1, #warned)
  end)

  it("clears a prior diagnostic after the ref is fixed and refreshed again", function()
    local root = make_project()
    local diagnostics = load_diagnostics()
    local buf = open_buffer(root, "models/staging/stg_customers.sql", "select * from {{ ref('does_not_exist') }}\n")

    diagnostics.refresh(buf)
    assert.equals(1, #vim.diagnostic.get(buf, { namespace = ns }))

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "select * from {{ ref('stg_orders') }}" })
    diagnostics.refresh(buf)

    assert.equals(0, #vim.diagnostic.get(buf, { namespace = ns }))
  end)

  it("parses a compile-error banner naming a file and message", function()
    local diagnostics = load_diagnostics()
    local errors = diagnostics.parse_run_output({
      "Running with dbt=1.7.0",
      "Compilation Error in model stg_orders (models/staging/stg_orders.sql)",
      "  'does_not_exist' is undefined",
      "",
    })

    assert.equals(1, #errors)
    assert.equals("models/staging/stg_orders.sql", errors[1].path)
    assert.matches("does_not_exist", errors[1].message)
  end)

  it("publishes a run-error diagnostic on the named open buffer", function()
    local root = make_project()
    local diagnostics = load_diagnostics()
    local buf = open_buffer(root, "models/staging/stg_orders.sql", "select 1\n")

    diagnostics.handle_run_output(root, {
      "Compilation Error in model stg_orders (models/staging/stg_orders.sql)",
      "  boom",
    })

    local diags = vim.diagnostic.get(buf, { namespace = ns })
    assert.equals(1, #diags)
    assert.equals(vim.diagnostic.severity.ERROR, diags[1].severity)
  end)

  it("drops errors naming a file that isn't open, without crashing", function()
    local root = make_project()
    local diagnostics = load_diagnostics()

    assert.has_no.errors(function()
      diagnostics.handle_run_output(root, {
        "Compilation Error in model stg_missing (models/staging/stg_missing.sql)",
        "  boom",
      })
    end)
  end)

  it("clears prior run-error diagnostics on a clean run", function()
    local root = make_project()
    local diagnostics = load_diagnostics()
    local buf = open_buffer(root, "models/staging/stg_orders.sql", "select 1\n")

    diagnostics.handle_run_output(root, {
      "Compilation Error in model stg_orders (models/staging/stg_orders.sql)",
      "  boom",
    })
    assert.equals(1, #vim.diagnostic.get(buf, { namespace = ns }))

    diagnostics.handle_run_output(root, { "Completed successfully" })

    assert.equals(0, #vim.diagnostic.get(buf, { namespace = ns }))
  end)

  it("publishes nothing false on unparseable output", function()
    local root = make_project()
    local diagnostics = load_diagnostics()
    local buf = open_buffer(root, "models/staging/stg_orders.sql", "select 1\n")

    diagnostics.handle_run_output(root, { "garbage output", "no banners here" })

    assert.equals(0, #vim.diagnostic.get(buf, { namespace = ns }))
  end)

  it("keeps U8 ref diagnostics and U9 run diagnostics coexisting in the namespace", function()
    local root = make_project()
    local diagnostics = load_diagnostics()
    local buf = open_buffer(root, "models/staging/stg_orders.sql", "select * from {{ ref('does_not_exist') }}\n")

    diagnostics.refresh(buf)
    diagnostics.handle_run_output(root, {
      "Compilation Error in model stg_orders (models/staging/stg_orders.sql)",
      "  boom",
    })

    assert.equals(2, #vim.diagnostic.get(buf, { namespace = ns }))
  end)
end)
