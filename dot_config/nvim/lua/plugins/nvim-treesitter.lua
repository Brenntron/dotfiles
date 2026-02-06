return {
  "nvim-treesitter/nvim-treesitter",
  opts = {
    -- Disable regex language globally to prevent crashes
    ignore_install = { "regex" },
    ensure_installed = {
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
      "javascript",
      "jinja",
      "json",
      "lua",
      "markdown",
      "markdown_inline",
      "python",
      "query",
      -- "regex", -- incompatible with nvim 0.11.6
      "ruby",
      "sql",
      "toml",
      "typescript",
      "vim",
      "vimdoc",
      "yaml",
    },
    highlight = {
      enable = true,
      disable = function(lang, buf)
        -- Disable regex language to prevent crashes
        if lang == "regex" then
          return true
        end
        return false
      end,
    },
  },
}
