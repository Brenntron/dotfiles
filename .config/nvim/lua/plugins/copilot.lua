local M = {
  "zbirenbaum/copilot.lua",
  cmd = 'Copilot',
  event = {"InsertEnter", "LspAttach" },
  opts = {
    copilot_node_command = vim.fn.expand("$HOME") .. "/.asdf/shims/node",
    filetypes = {
      sh = function ()
        if string.match(vim.fs.basename(vim.api.nvim_buf_get_name(0)), '^%.env.*') then
          return false
        end
        return true
      end,
    },
    suggestion = { enabled = false },
    panel = { enabled = false },
  },
}

return M
