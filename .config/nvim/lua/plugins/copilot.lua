local M = {
  "zbirenbaum/copilot.lua",
  event = {"LspAttach", "VimEnter" },
}

function M.config()
  require('copilot').setup {
    copilot_node_command = vim.fn.expand("$HOME") .. "/.asdf/shims/node",
    filetypes = {
      sh = function ()
        if string.match(vim.fs.basename(vim.api.nvim_buf_get_name(0))_, '^%.env.*') then
          return false
        end
        return true
      end,
    },
  }
end

return M
