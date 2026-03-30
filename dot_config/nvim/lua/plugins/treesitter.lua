-- Treesitter: syntax highlighting, textobjects, autotag
-- nvim-treesitter v1.x: highlight/indent are built into Neovim;
-- the plugin handles parser installation and queries.

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
  "ruby",
  "sql",
  "toml",
  "typescript",
  "vim",
  "vimdoc",
  "yaml",
})

-- Enable treesitter highlight and indent via FileType autocmd
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("bvim_treesitter", { clear = true }),
  callback = function(ev)
    if vim.bo[ev.buf].filetype == "regex" then
      return
    end
    pcall(vim.treesitter.start, ev.buf)
  end,
})

-- Textobjects
require("nvim-treesitter-textobjects").setup({
  select = { lookahead = true },
  move = { set_jumps = true },
})

local map = vim.keymap.set

-- Select textobjects
map({ "x", "o" }, "af", function() require("nvim-treesitter-textobjects.select").select_textobject("@function.outer", "textobjects") end, { desc = "Around function" })
map({ "x", "o" }, "if", function() require("nvim-treesitter-textobjects.select").select_textobject("@function.inner", "textobjects") end, { desc = "Inside function" })
map({ "x", "o" }, "ac", function() require("nvim-treesitter-textobjects.select").select_textobject("@class.outer", "textobjects") end, { desc = "Around class" })
map({ "x", "o" }, "ic", function() require("nvim-treesitter-textobjects.select").select_textobject("@class.inner", "textobjects") end, { desc = "Inside class" })
map({ "x", "o" }, "aa", function() require("nvim-treesitter-textobjects.select").select_textobject("@parameter.outer", "textobjects") end, { desc = "Around parameter" })
map({ "x", "o" }, "ia", function() require("nvim-treesitter-textobjects.select").select_textobject("@parameter.inner", "textobjects") end, { desc = "Inside parameter" })

-- Move textobjects
local move = require("nvim-treesitter-textobjects.move")
map({ "n", "x", "o" }, "]f", function() move.goto_next_start("@function.outer", "textobjects") end, { desc = "Next function start" })
map({ "n", "x", "o" }, "]F", function() move.goto_next_end("@function.outer", "textobjects") end, { desc = "Next function end" })
map({ "n", "x", "o" }, "]c", function() move.goto_next_start("@class.outer", "textobjects") end, { desc = "Next class start" })
map({ "n", "x", "o" }, "]C", function() move.goto_next_end("@class.outer", "textobjects") end, { desc = "Next class end" })
map({ "n", "x", "o" }, "]a", function() move.goto_next_start("@parameter.inner", "textobjects") end, { desc = "Next parameter" })
map({ "n", "x", "o" }, "[f", function() move.goto_previous_start("@function.outer", "textobjects") end, { desc = "Prev function start" })
map({ "n", "x", "o" }, "[F", function() move.goto_previous_end("@function.outer", "textobjects") end, { desc = "Prev function end" })
map({ "n", "x", "o" }, "[c", function() move.goto_previous_start("@class.outer", "textobjects") end, { desc = "Prev class start" })
map({ "n", "x", "o" }, "[C", function() move.goto_previous_end("@class.outer", "textobjects") end, { desc = "Prev class end" })
map({ "n", "x", "o" }, "[a", function() move.goto_previous_start("@parameter.inner", "textobjects") end, { desc = "Prev parameter" })

-- Swap textobjects
local swap = require("nvim-treesitter-textobjects.swap")
map("n", "<leader>cs", function() swap.swap_next("@parameter.inner", "textobjects") end, { desc = "Swap next parameter" })
map("n", "<leader>cS", function() swap.swap_previous("@parameter.inner", "textobjects") end, { desc = "Swap prev parameter" })

-- Autotag (auto close/rename HTML tags)
require("nvim-ts-autotag").setup()
