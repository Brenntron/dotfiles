local M = {}

-- Override the configuration with a user provided one
-- @param config_path The path to the configuration overrides
function M:reload()
  vim.schedule(function()
    reload "autocommands"

    require("deprecated").post_load()

    vim.g.mapleader = " "

    reload("keymappings")

    reload "Lazy"
  end)
end

return M
