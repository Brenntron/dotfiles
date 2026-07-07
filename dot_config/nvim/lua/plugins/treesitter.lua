-- Treesitter: syntax highlighting, textobjects, autotag
-- nvim-treesitter v1.x: highlight/indent are built into Neovim;
-- the plugin handles parser installation and queries.
-- Highlighting is started by the FileType autocmd in config/autocmds.lua.
-- Textobject keymaps live in config/keymaps.lua.

-- Install parsers
require("nvim-treesitter").install({
  "bash",
  "comment",
  "css",
  "diff",
  "dockerfile",
  "dot",
  "git_config",
  "git_rebase",
  "gitignore",
  "html",
  "htmldjango",
  "javascript",
  "json",
  "lua",
  "markdown",
  "markdown_inline",
  "python",
  "query",
  "regex",
  "ruby",
  "sql",
  "toml",
  "typescript",
  "vim",
  "vimdoc",
  "yaml",
})

-- Textobjects
require("nvim-treesitter-textobjects").setup({
  select = { lookahead = true },
  move = { set_jumps = true },
})

-- Autotag (auto close/rename HTML tags)
require("nvim-ts-autotag").setup()
