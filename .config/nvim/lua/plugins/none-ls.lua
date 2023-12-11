local M = {
  "nvimtools/none-ls.nvim",
  event = "BufReadPre",
  commit = "60b4a7167c79c7d04d1ff48b55f2235bf58158a7",
  dependencies = {
    {
      "nvim-lua/plenary.nvim",
      commit = "9a0d3bf7b832818c042aaf30f692b081ddd58bd9",
    },
  },
}

function M.config()
  local null_ls = require "null-ls"
  -- https://github.com/nvimtools/none-ls.nvim/blob/main/doc/BUILTINS.md#completion
  local completions = null_ls.builtins.completion
  -- https://github.com/nvimtools/none-ls.nvim/tree/main/lua/none-ls/builtins/diagnostics
  local diagnostics = null_ls.builtins.diagnostics
  -- https://github.com/nvimtools/none-ls.nvim/tree/main/lua/none-ls/builtins/formatting
  local formatting = null_ls.builtins.formatting
  -- https://github.com/nvimtools/none-ls.nvim/tree/main/lua/none-ls/builtins/hover
  local hover = null_ls.builtins.formatting
  -- https://github.com/nvimtools/none-ls.nvim/tree/main/lua/none-ls/builtins/helpders
  local helpers = require "null-ls.helpers"
  local coffeelint_query = {
    name = "coffeelint",
    filetype = "coffee",
  }

  -- https://github.com/prettier-solidity/prettier-plugin-solidity
  null_ls.setup {
    debug = false,
    sources = {
      -- completions
      completions.spell.with {
        filetypes = { "coffee", "erb", "eruby", "haml", "html", "markdown" },
      },
      -- diagnostics
      diagnostics.codespell.with {
        filetypes = { "coffee", "erb", "eruby", "haml", "html", "markdown" },
      },
      diagnostics.stylelint,
      diagnostics.haml_lint,
      diagnostics.rubocop,
      diagnostics.shellcheck,
      diagnostics.zsh,
      -- formatters
      formatting.beautysh.with {
        filetypes = { "bash", "zsh" },
      },
      formatting.erb_lint,
      formatting.markdownlint,
      formatting.pg_format,
      formatting.prettierd.with {
        extra_filetypes = { "toml" },
        extra_args = { "--no-semi", "--single-quote", "--jsx-single-quote" },
      },
      formatting.rubocop,
      formatting.sqlfluff,
      formatting.stylua,
      hover.dictionary,
    },
  }

  if not null_ls.is_registered(coffeelint_query) then
    local handle_coffeelint_output = function(params)
      if params.output and params.output.stdin then
        local parser = helpers.diagnostics.from_json {}
        local message
        local offenses = {}

        for _, offense in ipairs(params.output.stdin) do
          if offense.context then
            message = (offense.message .. " " .. offense.context)
          else
            message = offense.message
          end

          table.insert(offenses, {
            ruleId = offense.name,
            message = message,
            level = offense.level,
            line = offense.lineNumber,
          })
        end

        return parser { output = offenses }
      end

      return {}
    end

    local coffeelint = {
      name = "coffeelint",
      method = null_ls.methods.DIAGNOSTICS,
      filetypes = { "coffee" },
      generator = null_ls.generator {
        command = "coffeelint",
        args = { "-s", "-f", "coffeelint.json", "--reporter", "raw", "$FILENAME" },
        to_stdin = true,
        format = "json",
        check_exit_code = function(code, stderr)
          local success = code <= 1

          if not success then
            print(stderr)
          end

          return success
        end,
        on_output = handle_coffeelint_output,
      },
    }

    null_ls.register(coffeelint)
  end
end

return M
