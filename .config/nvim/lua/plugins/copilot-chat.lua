local M = {
  "CopilotC-Nvim/CopilotChat.nvim",
  build = "make tiktoken",
  branch = "canary",
  dependencies = {
    { "zbirenbaum/copilot.lua" },
    { "nvim-lua/plenary.nvim" },
  },
  event = {"InsertEnter", "LspAttach" },
  config = function()
    require("CopilotChat.integrations.cmp").setup()

    require("CopilotChat").setup {}
  end
}

return M
