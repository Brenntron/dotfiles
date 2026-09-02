-- Coding: mini.ai, mini.comment, mini.pairs, mini.surround, mini.snippets, ts-comments, yanky, undotree

-- devcontainer
require("devcontainer-cli").setup({
  -- only the most useful options shown; see full config below
  interactive = false,
  toplevel = true,
  remove_existing_container = true,
  dotfiles_repository = "https://github.com/erichlf/dotfiles.git",
  dotfiles_branch = "devcontainer-cli",
  dotfiles_targetPath = "~/dotfiles",
  dotfiles_installCommand = "install.sh",
  shell = "bash",
  nvim_binary = "nvim",
  log_level = "debug",
  console_level = "info",
})

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
