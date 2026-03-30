-- Coding: mini.ai, mini.pairs, mini.surround, mini.snippets, ts-comments, yanky, undotree

-- Mini.ai (enhanced text objects)
require("mini.ai").setup({
  n_lines = 500,
  custom_textobjects = {
    o = require("mini.ai").gen_spec.treesitter({
      a = { "@block.outer", "@conditional.outer", "@loop.outer" },
      i = { "@block.inner", "@conditional.inner", "@loop.inner" },
    }),
    f = require("mini.ai").gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }),
    c = require("mini.ai").gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }),
    a = require("mini.ai").gen_spec.treesitter({ a = "@parameter.outer", i = "@parameter.inner" }),
  },
})

-- Mini.pairs (auto-close brackets, quotes)
require("mini.pairs").setup()

-- Mini.surround (add/delete/change surroundings)
require("mini.surround").setup({
  mappings = {
    add = "gsa",
    delete = "gsd",
    find = "gsf",
    find_left = "gsF",
    highlight = "gsh",
    replace = "gsr",
    update_n_lines = "gsn",
  },
})

-- Mini.snippets (snippet engine with friendly-snippets)
local snippets = require("mini.snippets")
snippets.setup({
  snippets = {
    snippets.gen_loader.from_lang(),
  },
})

-- ts-comments (context-aware commenting)
require("ts-comments").setup()

-- Yanky (improved yank/put)
require("yanky").setup({
  highlight = { timer = 200 },
})

-- Undotree
require("undotree").setup()
