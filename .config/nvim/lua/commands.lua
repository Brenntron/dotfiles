local M = {}

M.command_list = {
  {
    -- Override the configuration with a user provided one
    -- @param config_path The path to the configuration overrides
    name = "ReloadNvim",
    fn = function()
      vim.schedule(function()
        local commands = require "commands"

        commands.load(commands.command_list)

        vim.g.mapleader = " "

        reload "options"
        reload "keymaps"
        reload "autocommands"
      end)
    end,
  },
  {
    name = "SyncPlugins",
    fn = function()
      vim.schedule(function()
        reload "Lazy"
      end)
    end,
  },
}

function M.load(collection)
  local common_opts = { force = true}

  for _, cmd in pairs(collection) do
    local opts = vim.tbl_deep_extend("force", common_opts, cmd.opts or {})
    vim.api.nvim_create_user_command(cmd.name, cmd.fn, opts)
  end
end

return M
