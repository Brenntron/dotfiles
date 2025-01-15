local M = {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  dependencies = {
    {
      "windwp/nvim-ts-autotag",
      event = "VeryLazy",
    },
    {
      "andymass/vim-matchup",
      init = function()
        vim.g.matchup_matchparen_offscreen = { method = "popup" }
      end,
    },
    {
      "liadOz/nvim-dap-repl-highlights",
      event = "VeryLazy",
    },
    {
      "nvim-treesitter/nvim-treesitter-textobjects",
    },
  },
  event = { "BufNewFile", "BufReadPost" },
  config = function()
    vim.g.skip_ts_context_commenstring_module = true

    require("nvim-treesitter.configs").setup {
      auto_install = true,
      ensure_installed = {
        "bash",
        "c",
        "c_sharp",
        "clojure",
        "cmake",
        "comment",
        "css",
        "csv",
        "dap_repl",
        "diff",
        "dockerfile",
        "dot",
        "eex",
        "elixir",
        "elm",
        "erlang",
        "git_config",
        "git_rebase",
        "gitattributes",
        "gitignore",
        "go",
        "gpg",
        "graphql",
        "haskell",
        "html",
        "http",
        "git_config",
        "java",
        "javascript",
        "json",
        "json5",
        "kotlin",
        "llvm",
        "lua",
        "luadoc",
        "make",
        "markdown",
        "markdown_inline",
        "nix",
        "pug",
        "puppet",
        "python",
        "regex",
        "ruby",
        "rust",
        "scss",
        "ssh_config",
        "swift",
        "sql",
        "toml",
        "typescript",
        "vim",
        "vimdoc",
        "vue",
        "xml",
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
          lookahead = true,
          keymaps = {
            -- You can use the capture groups defined in textobjects.scm
            ["af"] = "@function.outer",
            ["if"] = "@function.inner",
            ["ac"] = "@class.outer",
            -- You can optionally set descriptions to the mappings (used in the desc parameter of
            -- nvim_buf_set_keymap) which plugins like which-key display
            ["ic"] = { query = "@class.inner", desc = "Select inner part of a class region" },
            -- You can also use captures from other query groups like `locals.scm`
            ["as"] = { query = "@local.scope", query_group = "locals", desc = "Select language scope" },
          },
          -- You can choose the select mode (default is charwise 'v')
          --
          -- Can also be a function which gets passed a table with the keys
          -- * query_string: eg '@function.inner'
          -- * method: eg 'v' or 'o'
          -- and should return the mode ('v', 'V', or '<c-v>') or a table
          -- mapping query_strings to modes.
          selection_modes = {
            ['@parameter.outer'] = 'v', -- charwise
            ['@function.outer'] = 'V', -- linewise
            ['@class.outer'] = '<c-v>', -- blockwise
          },
          -- If you set this to `true` (default is `false`) then any textobject is
          -- extended to include preceding or succeeding whitespace. Succeeding
          -- whitespace has priority in order to act similarly to eg the built-in
          -- `ap`.
          --
          -- Can also be a function which gets passed a table with the keys
          -- * query_string: eg '@function.inner'
          -- * selection_mode: eg 'v'
          -- and should return true or false
          include_surrounding_whitespace = true,
        },
      },
      sync_install = false,
    }
  end
}

return M
