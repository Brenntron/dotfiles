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
  }
end

return M
