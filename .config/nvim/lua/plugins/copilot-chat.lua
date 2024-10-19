local M = {
  "CopilotC-Nvim/CopilotChat.nvim",
  branch = "canary",
  event = {"InsertEnter", "LspAttach" },
  dependencies = {
    { "zbirenbaum/copilot.lua" },
    { "nvim-lua/plenary.nvim" },
  },
}

function M.config()
  require("CopilotChat.integrations.cmp").setup()

  require("CopilotChat").setup {
    debug = true,
    mappings = {
      complete = {
        insert = '',
      },
    },
    window = {
      layout = 'float',
      title = 'Copilot Chat'
    }
  }
end

return M
