-- Specs for compiled-SQL preview (U3).
-- Builds a temp dbt project fixture and drives dbt-nvim.compiled.preview().

local function write(path, content)
  vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
  local fd = assert(io.open(path, "w"))
  fd:write(content)
  fd:close()
end

-- Create a throwaway dbt project with a manifest and (optionally) a compiled
-- artifact for `stg_orders`. Returns the project root.
local function make_project(opts)
  opts = opts or {}
  local root = vim.fn.tempname()
  write(root .. "/dbt_project.yml", "name: acme\n")

  local manifest = {
    nodes = {
      ["model.acme.stg_orders"] = {
        resource_type = "model",
        name = "stg_orders",
        package_name = "acme",
        original_file_path = "models/staging/stg_orders.sql",
        compiled_path = vim.NIL,
      },
    },
    sources = {},
  }
  write(root .. "/target/manifest.json", vim.fn.json_encode(manifest))

  if opts.with_compiled ~= false then
    write(root .. "/target/compiled/acme/models/staging/stg_orders.sql", "select 1 as compiled_marker\n")
  end
  return root
end

local warned
local function load_compiled()
  package.loaded["dbt-nvim.util"] = nil
  package.loaded["dbt-nvim.compiled"] = nil
  local util = require("dbt-nvim.util")
  warned = {}
  util.notify = function(level, msg)
    table.insert(warned, { level = level, msg = msg })
  end
  return require("dbt-nvim.compiled"), util
end

-- Open a real .sql model buffer inside `root` so util resolves root + model name.
local function open_model(root)
  vim.cmd("edit " .. root .. "/models/staging/stg_orders.sql")
end

describe("dbt-nvim.compiled", function()
  after_each(function()
    pcall(vim.cmd, "bufdo bdelete!")
    package.loaded["dbt-nvim.compiled"] = nil
    package.loaded["dbt-nvim.util"] = nil
  end)

  it("opens compiled SQL for the model under cursor", function()
    local root = make_project()
    local compiled = load_compiled()
    open_model(root)

    assert.is_true(compiled.preview())

    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    assert.equals("select 1 as compiled_marker", lines[1])
    assert.equals("sql", vim.bo.filetype)
    assert.is_false(vim.bo.modifiable)
  end)

  it("warns and opens nothing when no compiled artifact exists", function()
    local root = make_project({ with_compiled = false })
    local compiled = load_compiled()
    open_model(root)

    assert.is_false(compiled.preview())
    assert.equals(1, #warned)
    assert.matches("DbtCompile", warned[1].msg)
  end)

  it("warns when the buffer is not a .sql model", function()
    local root = make_project()
    local compiled = load_compiled()
    vim.cmd("edit " .. root .. "/notes.md")

    assert.is_false(compiled.preview())
    assert.equals(1, #warned)
  end)

  it("warns when outside a dbt project", function()
    local compiled = load_compiled()
    vim.cmd("enew")
    vim.cmd("file /tmp/loose_file.sql")

    assert.is_false(compiled.preview())
    assert.equals(1, #warned)
  end)
end)
