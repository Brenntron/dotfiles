local M = {
  "windwp/nvim-ts-autotag",
}

function M.config()
  require("nvim-ts-autotag").setup()
end

return M
