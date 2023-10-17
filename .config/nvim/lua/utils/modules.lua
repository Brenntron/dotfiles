local M = {}

local function _assign(old, new, k)
  local old_type = type(old[k])
  local new_type = type(new[k])

  if (old_type == "thread" or old_type == "userdata") or (new_type == "thread" or new_type == "userdata") then
    vim.notify(string.format("warning: old or new attr %s type is thread or userdata", k))
  end
  old[k] = new[k]
end

local function _replace(old, new, repeat_tbl)
  if repeat_tbl[old] then
    return
  end

  repeat_tbl[old] = true

  local dellist = {}

  for k, _ in pairs (old) do
    if not new[k] then
      table.insert(dellist, k)
    end
  end

  for _, v in ipairs(dellist) do
    old[v] = nil
  end

  for k, _ in pairs(new) do
    if not old[k] then
      old[k] = new[k]
    else
      if type(old[k]) == "table" then
        _replace(old[k], new[k], repeat_tbl)
      else
        _assign(old, new, k)
      end
    end
  end
end

M.require_safe = function(mod)
  local _, module = pcall(require, mod)
  return module
end

M.reload = function(mod)
  if not package.loaded[mod] then
    return M.require_safe(mod)
  end

  local old = package.loaded[mod]
  package.loaded[mod] = nil
  local new = M.require_safe(mod)

  if type(old) == "table" and type(new) == "table" then
    local repeat_tbl = {}
    _replace(old, new, repeat_tbl)
  end

  package.loaded[mod] = old
  return old
end

return M
