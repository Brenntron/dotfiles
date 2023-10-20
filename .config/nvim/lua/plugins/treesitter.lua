local M = {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  commit = "afa103385a2b5ef060596ed822ef63276ae88016",
  dependencies = {
    {
      "windwp/nvim-autopairs",
      event = "InsertEnter",
      commit = "f6c71641f6f183427a651c0ce4ba3fb89404fa9e",
    },
    {
      "nvim-treesitter/nvim-treesitter-textobjects",
      event = "VeryLazy",
      commit = "78c49ca7d2f7ccba2115c11422c037713c978ad1",
    },
    {
      "windwp/nvim-ts-autotag",
      event = "VeryLazy",
      commit = "6be1192965df35f94b8ea6d323354f7dc7a557e4",
    },
    {
      "JoosepAlviste/nvim-ts-context-commentstring",
      event = "VeryLazy",
      commit = "92e688f013c69f90c9bbd596019ec10235bc51de",
    },
  },
  event = { "BufNewFile", "BufReadPost" },
}

function M.config()
  require("nvim-treesitter.configs").setup {
    autopairs = {
      enable = true,
    },
    autotag = { enable = true },
    context_commentstring = {
      enable = true,
      enable_autocmd = false,
    },
    ensure_installed = {
      "bash",
      "comment",
      "dockerfile",
      "dot",
      "gitignore",
      "html",
      "git_config",
      "javascript",
      "lua",
      "markdown",
      "markdown_inline",
      "regex",
      "ruby",
      "scss",
      "sql",
      "vim",
      "vue",
      "yaml",
    },
    -- ensure_installed = "all", -- one of "all" or a list of languages
    highlight = {
      additional_vim_regex_highlighting = false,
      enable = true, -- false will disable the whole extension
      disable = { "markdown" }, -- list of language that will be disabled
    },
    ignore_install = { "" }, -- List of parsers to ignore installing
    indent = { enable = true },
    matchup = {
      enable = {},
      disable = { "lua" },
    },
    sync_install = false, -- install languages synchronously (only applied to `ensure_installed`)
    textobjects = {
      select = {
        enable = true,
        -- Automatically jump forward to textobj, similar to targets.vim
        keymaps = {
          -- You can use the capture groups defined in textobjects.scm
          ["af"] = "@function.outer",
          ["if"] = "@function.inner",
          ["at"] = "@class.outer",
          ["it"] = "@class.inner",
          ["ac"] = "@call.outer",
          ["ic"] = "@call.inner",
          ["aa"] = "@parameter.outer",
          ["ia"] = "@parameter.inner",
          ["al"] = "@loop.outer",
          ["il"] = "@loop.inner",
          ["ai"] = "@conditional.outer",
          ["ii"] = "@conditional.inner",
          ["a/"] = "@comment.outer",
          ["i/"] = "@comment.inner",
          ["ab"] = "@block.outer",
          ["ib"] = "@block.inner",
          ["as"] = "@statement.outer",
          ["is"] = "@scopename.inner",
          ["aA"] = "@attribute.outer",
          ["iA"] = "@attribute.inner",
          ["aF"] = "@frame.outer",
          ["iF"] = "@frame.inner",
        },
        lookahead = true,
      }
    }
  }
end

return M
