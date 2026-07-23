local util = require("dbt-nvim.util")
local terminal = require("dbt-nvim.terminal")

local D = {}
local uv = vim.uv or vim.loop
local manifest_cache = {}

D.setup = function()
  vim.api.nvim_create_user_command("DbtCompile", function()
    D.compile()
  end, {})
  vim.api.nvim_create_user_command("DbtModelYaml", function()
    D.model_yaml()
  end, {})
  vim.api.nvim_create_user_command("DbtRun", function()
    D.run()
  end, {})
  vim.api.nvim_create_user_command("DbtBuild", function()
    D.build()
  end, {})
  vim.api.nvim_create_user_command("DbtBuildSelect", function()
    D.build_select()
  end, {})
  vim.api.nvim_create_user_command("DbtRunFull", function()
    D.run_full()
  end, {})
  vim.api.nvim_create_user_command("DbtRerunLast", function()
    terminal.rerun()
  end, {})
  vim.api.nvim_create_user_command("DbtCompiledPreview", function()
    require("dbt-nvim.compiled").preview()
  end, {})
  vim.api.nvim_create_user_command("DbtLineage", function()
    require("dbt-nvim.lineage").open()
  end, {})
  vim.api.nvim_create_user_command("DbtTest", function()
    D.test()
  end, {})
  vim.api.nvim_create_user_command("DbtListDownstreamModels", function()
    D.list_downstream_models()
  end, {})
  vim.api.nvim_create_user_command("DbtListUpstreamModels", function()
    D.list_upstream_models()
  end, {})
  vim.api.nvim_create_user_command("DbtGoToDefinition", function()
    D.goto_definition()
  end, {})
  vim.api.nvim_create_user_command("DbtDiagnosticsRefresh", function()
    require("dbt-nvim.diagnostics").refresh(vim.api.nvim_get_current_buf())
  end, {})
  vim.api.nvim_create_user_command("DbtRunDefer", function()
    D.run_defer()
  end, {})
  vim.api.nvim_create_user_command("DbtLogsTail", function()
    D.logs_tail()
  end, {})
  vim.api.nvim_create_user_command("DbtDeps", function()
    terminal.open({ "dbt", "deps" })
  end, {})
  vim.api.nvim_create_user_command("DbtSeed", function()
    D.seed()
  end, {})
  vim.api.nvim_create_user_command("DbtSnapshot", function()
    terminal.open({ "dbt", "snapshot" })
  end, {})

  vim.api.nvim_create_autocmd("FileType", {
    pattern = "sql.jinja",
    callback = function(args)
      D._maybe_attach_buffer(args.buf)
    end,
  })
end

local notify = util.notify

local function join_paths(root, rel)
  if rel:match("^%a:[\\/]") or rel:sub(1, 1) == "/" then
    return rel
  end
  if vim.fs and vim.fs.joinpath then
    return vim.fs.normalize(vim.fs.joinpath(root, rel))
  end
  local separator = package.config:sub(1, 1)
  local path = root .. separator .. rel
  return vim.fn.fnamemodify(path, ":p")
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

local function get_project_root(bufnr)
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

D.get_manifest_index = function(root)
  local manifest_path = join_paths(root, "target/manifest.json")
  local stat = uv and uv.fs_stat(manifest_path) or nil
  if not stat then
    return nil, "dbt manifest not found. Run dbt compile to generate it."
  end
  local mtime = stat.mtime and (stat.mtime.sec or stat.mtime) or 0
  local cached = manifest_cache[manifest_path]
  if cached and cached.mtime == mtime then
    return cached.index
  end
  local content = read_file(manifest_path)
  if not content then
    return nil, "Unable to read dbt manifest at " .. manifest_path
  end
  local ok, manifest = pcall(vim.fn.json_decode, content)
  if not ok then
    return nil, "Failed to parse dbt manifest.json"
  end
  local index = { models = {}, sources = {} }
  for _, node in pairs(manifest.nodes or {}) do
    if node.resource_type == "model" and node.original_file_path and node.name then
      local absolute = join_paths(root, node.original_file_path)
      index.models[node.name] = absolute
      if node.package_name then
        index.models[node.package_name .. "." .. node.name] = absolute
      end
    end
  end
  for _, node in pairs(manifest.sources or {}) do
    if node.source_name and node.name and node.original_file_path then
      local absolute = join_paths(root, node.original_file_path)
      local key = string.format("%s:%s", node.source_name, node.name)
      index.sources[key] = absolute
    end
  end
  manifest_cache[manifest_path] = { mtime = mtime, index = index }
  return index
end

local MODEL_REF_PATTERN = "ref%(%s*['\"]([^'\"]+)['\"]%s*%)"
local SOURCE_REF_PATTERN = "source%(%s*['\"]([^'\"]+)['\"]%s*,%s*['\"]([^'\"]+)['\"]%s*%)"

local function find_model_reference(line, column)
  local search_from = 1
  while true do
    local s, e, name = line:find(MODEL_REF_PATTERN, search_from)
    if not s then
      break
    end
    if column >= s and column <= e then
      local package, model = name:match("^([^.]+)%.(.+)$")
      if package and model then
        return { type = "model", full = name, key = model, start_col = s, end_col = e }
      end
      return { type = "model", full = name, key = name, start_col = s, end_col = e }
    end
    search_from = e + 1
  end
end

local function find_source_reference(line, column)
  local search_from = 1
  while true do
    local s, e, source_name, table_name = line:find(SOURCE_REF_PATTERN, search_from)
    if not s then
      break
    end
    if column >= s and column <= e then
      return {
        type = "source",
        source = source_name,
        name = table_name,
        full = source_name .. ":" .. table_name,
        start_col = s,
        end_col = e,
      }
    end
    search_from = e + 1
  end
end

local function find_reference_under_cursor()
  local line = vim.api.nvim_get_current_line()
  local _, col = unpack(vim.api.nvim_win_get_cursor(0))
  local column = col + 1
  return find_model_reference(line, column) or find_source_reference(line, column)
end

-- Iterate every ref()/source() call on `line`, regardless of cursor position.
-- Used by diagnostics.lua to scan a whole buffer for unresolved references.
D.iter_references = function(line)
  local refs = {}
  local search_from = 1
  while true do
    local s, e, name = line:find(MODEL_REF_PATTERN, search_from)
    if not s then
      break
    end
    local package, model = name:match("^([^.]+)%.(.+)$")
    table.insert(refs, { type = "model", full = name, key = model or name, start_col = s, end_col = e })
    search_from = e + 1
  end
  search_from = 1
  while true do
    local s, e, source_name, table_name = line:find(SOURCE_REF_PATTERN, search_from)
    if not s then
      break
    end
    table.insert(refs, {
      type = "source",
      source = source_name,
      name = table_name,
      full = source_name .. ":" .. table_name,
      start_col = s,
      end_col = e,
    })
    search_from = e + 1
  end
  local i = 0
  return function()
    i = i + 1
    return refs[i]
  end
end

D.goto_definition = function()
  local ref = find_reference_under_cursor()
  if not ref then
    return false
  end
  local bufnr = vim.api.nvim_get_current_buf()
  local ok, root = pcall(vim.api.nvim_buf_get_var, bufnr, "dbt_project_root")
  if not ok or not root then
    root = get_project_root(bufnr)
    if root then
      pcall(vim.api.nvim_buf_set_var, bufnr, "dbt_project_root", root)
    end
  end
  if not root then
    notify("WARN", "Not inside a dbt project (missing dbt_project.yml).")
    return false
  end
  local index, err = D.get_manifest_index(root)
  if not index then
    if err then
      notify("WARN", err)
    end
    return false
  end
  local target
  if ref.type == "model" then
    target = index.models[ref.full] or index.models[ref.key]
  else
    target = index.sources[ref.full]
  end
  if not target or vim.fn.filereadable(target) == 0 then
    notify("WARN", "Definition not found for " .. ref.full .. ".")
    return false
  end
  vim.cmd("edit " .. vim.fn.fnameescape(target))
  return true
end

D._maybe_attach_buffer = function(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == "" or vim.fn.fnamemodify(name, ":e") ~= "sql" then
    return
  end
  local root = get_project_root(bufnr)
  if not root then
    return
  end
  local ok, attached = pcall(vim.api.nvim_buf_get_var, bufnr, "dbt_gd_attached")
  if ok and attached then
    return
  end
  pcall(vim.api.nvim_buf_set_var, bufnr, "dbt_project_root", root)
  -- gd chain: manifest ref/source resolution first (dbt-aware), then the
  -- LSP's definition (macros etc.), then native gd. Single owner for this
  -- filetype so there's no registration race with the generic LspAttach gd
  -- in lua/plugins/lsp.lua (which explicitly skips sql.jinja).
  vim.keymap.set("n", "gd", function()
    if D.goto_definition() then
      return
    end
    local clients = vim.lsp.get_clients({ bufnr = bufnr })
    if #clients > 0 then
      vim.lsp.buf.definition()
      return
    end
    vim.cmd("normal! gd")
  end, { buffer = bufnr, silent = true })
  vim.api.nvim_buf_set_var(bufnr, "dbt_gd_attached", true)
end

-- Get the model name from the current file if it's an SQL file
D.get_model_name = util.get_model_name

-- dbt command functions
D.run = function()
  D._run_dbt("run")
end
D.build = function()
  D._run_dbt("build")
end

-- Build the buffer's model with a chosen graph scope: the model alone, its
-- downstream (`model+`), upstream (`+model`), or both (`+model+`). dbt's `+`
-- operator is positional; see `_list_models` for the same selector shapes.
D.build_select = function()
  if D.get_model_name() == nil then
    return
  end
  local choices = {
    { label = "Model only", selector = "%s" },
    { label = "Downstream (model+)", selector = "%s+" },
    { label = "Upstream (+model)", selector = "+%s" },
    { label = "Both (+model+)", selector = "+%s+" },
  }
  vim.ui.select(choices, {
    prompt = "dbt build scope:",
    format_item = function(item)
      return item.label
    end,
  }, function(choice)
    if not choice then
      return
    end
    D._run_dbt("build", nil, choice.selector)
  end)
end
D.run_full = function()
  D._run_dbt("run", "--full-refresh")
end
D.test = function()
  D._run_dbt("test")
end
D.compile = function()
  D._run_dbt("compile")
end

-- Prod-manifest path for `--defer --state`. Set via `vim.g.dbt_defer_state_path`
-- (documented module-level config var); falls back to a one-time
-- vim.ui.input prompt when unset (Open Questions: exact source deferred to
-- implementation).
D.run_defer = function()
  local state_path = vim.g.dbt_defer_state_path
  if not state_path or state_path == "" then
    state_path = vim.fn.input("dbt defer state path (prod manifest dir): ")
    if state_path == "" then
      return
    end
  end
  if vim.fn.isdirectory(state_path) == 0 then
    notify("WARN", "Defer state path does not exist: " .. state_path)
    return
  end
  D._run_dbt("run", { "--defer", "--state", state_path })
end

-- dbt project's log-path: (falls back to logs/dbt.log). Read once per call
-- rather than cached, since it's cheap and the project.yml can change.
local function resolve_log_path(root)
  local log_dir = "logs"
  local content = read_file(join_paths(root, "dbt_project.yml"))
  if content then
    local override = content:match("[\r\n]log%-path:%s*['\"]?([^'\"\r\n]+)")
    if override then
      log_dir = vim.trim(override)
    end
  end
  return join_paths(root, join_paths(log_dir, "dbt.log"))
end

-- Live-tail the resolved dbt log in a persistent, scrollable floating host.
D.logs_tail = function()
  local root = get_project_root(vim.api.nvim_get_current_buf())
  if not root then
    notify("WARN", "Not inside a dbt project (missing dbt_project.yml).")
    return
  end
  local log_path = resolve_log_path(root)
  if vim.fn.filereadable(log_path) == 0 then
    notify("WARN", "No dbt log found at " .. log_path .. ". Run a dbt command first.")
    return
  end
  terminal.open({ "tail", "-F", log_path }, { interactive = false })
end

-- DbtSeed takes the current buffer's selector when it resolves to a model
-- name (e.g. editing a seed CSV's companion), else runs project-wide.
D.seed = function()
  local model_name = D.get_model_name()
  local cmd = { "dbt", "seed" }
  if model_name then
    vim.list_extend(cmd, { "-s", model_name })
  end
  terminal.open(cmd)
end
D.model_yaml = function()
  local model_name = D.get_model_name()
  if model_name == nil then
    return
  end
  local command =
    { "dbt", "run-operation", "generate_model_yaml", "--args", '{"model_names": ["' .. model_name .. '"]}' }
  terminal.open(command)
end

-- Helper to run dbt commands with model selector. `selector_tmpl` is an
-- optional format string with a single `%s` for the model name (e.g. "+%s+");
-- defaults to the bare model name.
D._run_dbt = function(command, params, selector_tmpl)
  local model_name = D.get_model_name()
  if model_name == nil then
    return
  end
  local cmd = { "dbt", command }
  if params then
    if type(params) == "table" then
      vim.list_extend(cmd, params)
    else
      table.insert(cmd, params)
    end
  end
  local selector = selector_tmpl and selector_tmpl:format(model_name) or model_name
  vim.list_extend(cmd, { "-s", selector })
  local root = get_project_root(vim.api.nvim_get_current_buf())
  terminal.open(cmd, {
    on_exit = root
      and function(lines)
        require("dbt-nvim.diagnostics").handle_run_output(root, lines)
      end
      or nil,
  })
end

-- Snacks picker functionality
local snacks_ok, snacks = pcall(require, "snacks")
if not snacks_ok then
  notify("ERROR", "snacks.nvim is not installed. Please install folke/snacks.nvim")
end

-- Get command output lines
local function get_command_output_lines(cmd)
  local handle = io.popen(cmd)
  local result = {}
  if handle then
    for line in handle:lines() do
      table.insert(result, line)
    end
    handle:close()
  end
  return result
end

-- Parse dbt JSON lines and return formatted entries
local function parse_dbt_json_lines(output_lines)
  local entries = {}
  local path_map = {}
  for _, line in ipairs(output_lines) do
    if line ~= "" then
      local entry = vim.fn.json_decode(line)
      local formatted_entry = entry.unique_id
      table.insert(entries, formatted_entry)
      path_map[formatted_entry] = entry.original_file_path
    end
  end
  return entries, path_map
end

-- Populate snacks picker with dbt list output
local function populate_picker(entries, path_map, title)
  if not snacks_ok then
    notify("ERROR", "snacks.nvim is required for this feature")
    return
  end

  -- Transform entries into picker items with text and file path
  local items = {}
  for _, entry in ipairs(entries) do
    table.insert(items, {
      text = entry,
      file = path_map[entry],
    })
  end

  snacks.pick({
    title = title,
    items = items,
    format = function(item)
      return item.text
    end,
    confirm = function(item)
      if item.file then
        vim.cmd("edit " .. vim.fn.fnameescape(item.file))
      else
        notify("WARN", "No file path found for the selected entry.")
      end
    end,
  })
end

-- List Upstream/Downstream models using dbt list --output json
D.list_upstream_models = function()
  D._list_models("<selector>+", "Upstream Models")
end
D.list_downstream_models = function()
  D._list_models("+<selector>", "Downstream Models")
end

D._list_models = function(selector, title)
  local model_name = D.get_model_name()
  if model_name == nil then
    return
  end
  local selector_with_model = selector:gsub("<selector>", model_name)
  local escaped_selector = vim.fn.shellescape(selector_with_model)
  local cmd =
    string.format("dbt list -s %s --output json -q --output-keys unique_id original_file_path", escaped_selector)
  local output = get_command_output_lines(cmd)
  local entries, path_map = parse_dbt_json_lines(output)
  populate_picker(entries, path_map, title)
end
return D
