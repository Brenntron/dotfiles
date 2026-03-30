-- Chezmoi: chezmoi.vim (syntax) + chezmoi.nvim (editing/watching)

-- chezmoi.vim globals
vim.g["chezmoi#use_tmp_buffer"] = 1
vim.g["chezmoi#source_dir_path"] = vim.env.HOME .. "/.local/share/chezmoi"

-- chezmoi.nvim
require("chezmoi").setup({
  edit = {
    watch = false,
    force = false,
  },
  notification = {
    on_open = true,
    on_apply = true,
    on_watch = false,
  },
})

-- Auto-watch chezmoi source files on open
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  group = vim.api.nvim_create_augroup("bvim_chezmoi", { clear = true }),
  pattern = { vim.env.HOME .. "/.local/share/chezmoi/*" },
  callback = function()
    vim.schedule(require("chezmoi.commands.__edit").watch)
  end,
})

-- Chezmoi file picker via Snacks
local function pick_chezmoi()
  local results = require("chezmoi.commands").list({
    args = {
      "--path-style",
      "absolute",
      "--include",
      "files",
      "--exclude",
      "externals",
    },
  })
  local items = {}
  for _, czFile in ipairs(results) do
    table.insert(items, {
      text = czFile,
      file = czFile,
    })
  end
  Snacks.picker.pick({
    items = items,
    confirm = function(picker, item)
      picker:close()
      require("chezmoi.commands").edit({
        targets = { item.text },
        args = { "--watch" },
      })
    end,
  })
end

-- Keymap is in config/keymaps.lua
_G.pick_chezmoi = pick_chezmoi

-- Mini.icons for chezmoi files
require("mini.icons").setup({
  file = {
    [".chezmoiignore"] = { glyph = "", hl = "MiniIconsGrey" },
    [".chezmoiremove"] = { glyph = "", hl = "MiniIconsGrey" },
    [".chezmoiroot"] = { glyph = "", hl = "MiniIconsGrey" },
    [".chezmoiversion"] = { glyph = "", hl = "MiniIconsGrey" },
    ["bash.tmpl"] = { glyph = "", hl = "MiniIconsGrey" },
    ["json.tmpl"] = { glyph = "", hl = "MiniIconsGrey" },
    ["ps1.tmpl"] = { glyph = "󰨊", hl = "MiniIconsGrey" },
    ["sh.tmpl"] = { glyph = "", hl = "MiniIconsGrey" },
    ["toml.tmpl"] = { glyph = "", hl = "MiniIconsGrey" },
    ["yaml.tmpl"] = { glyph = "", hl = "MiniIconsGrey" },
    ["zsh.tmpl"] = { glyph = "", hl = "MiniIconsGrey" },
  },
})
