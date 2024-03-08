local M = {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  dependencies = {
    {
      "windwp/nvim-autopairs",
      event = "InsertEnter",
    },
    {
      "nvim-treesitter/nvim-treesitter-textobjects",
      event = "VeryLazy",
    },
    {
      "windwp/nvim-ts-autotag",
      event = "VeryLazy",
    },
    {
      "andymass/vim-matchup",
      config = function()
        vim.g.matchup_matchparen_offscreen = { method = "popup" }
      end,
    },
    {
      "liadOz/nvim-dap-repl-highlights",
      event = "VeryLazy",
      config = function()
        require("nvim-dap-repl-highlights").setup()
      end,
    },
  },
  event = { "BufNewFile", "BufReadPost" },
}

function M.config()
  vim.g.skip_ts_context_commenstring_module = true

  require("nvim-treesitter.configs").setup {
    autotag = { enable = true },
    ensure_installed = {
      "bash",
      "comment",
      "dap_repl",
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
      "vimdoc",
      "vue",
      "yaml",
    },
    -- ensure_installed = "all", -- one of "all" or a list of languages
    highlight = {
      additional_vim_regex_highlighting = false,
      enable = true, -- false will disable the whole extension
    },
    ignore_install = { "" }, -- List of parsers to ignore installing
    indent = { enable = true },
    matchup = {
      enable = true,
    },
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
