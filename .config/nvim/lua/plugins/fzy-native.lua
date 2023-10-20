local M = {
  "nvim-telescope/telescope-fzy-native.nvim",
  dependencies = {
    "nvim-telescope/telescope.nvim"
  }
}

function M.config()
  require('telescope').load_extension 'fzy_native'
end

return M
