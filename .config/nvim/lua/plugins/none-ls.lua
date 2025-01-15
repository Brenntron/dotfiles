local M = {
  "nvimtools/none-ls.nvim",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    {
      "nvim-lua/plenary.nvim",
    },
  },
  config = function()
    local null_ls = require "null-ls"
    -- https://github.com/nvimtools/none-ls.nvim/blob/main/doc/BUILTINS.md#completion
    local completions = null_ls.builtins.completion
    -- https://github.com/nvimtools/none-ls.nvim/tree/main/lua/none-ls/builtins/diagnostics
    local diagnostics = null_ls.builtins.diagnostics
    -- https://github.com/nvimtools/none-ls.nvim/tree/main/lua/none-ls/builtins/formatting
    local formatting = null_ls.builtins.formatting
    -- https://github.com/nvimtools/none-ls.nvim/tree/main/lua/none-ls/builtins/helpers
    local helpers = require "null-ls.helpers"
    local coffeelint_query = {
      name = "coffeelint",
      filetype = "coffee",
    }
    local coffee_fmt_query = {
      name = "coffee_fmt",
      filetype = "coffee",
    }

    -- https://github.com/prettier-solidity/prettier-plugin-solidity
    null_ls.setup {
      debug = false,
      sources = {
        -- completions
        completions.spell.with {
          filetypes = { "coffee", "css", "cucumber", "erb", "eruby", "javascript", "haml", "html", "markdown", "scss", "yaml" },
        },
        -- diagnostics
        diagnostics.codespell.with {
          filetypes = { "coffee", "css", "cucumber", "erb", "eruby", "javascript", "haml", "html", "markdown", "scss", "yaml" },
        },
        diagnostics.erb_lint,
        diagnostics.haml_lint,
        diagnostics.stylelint,
        diagnostics.zsh,
        -- formatters
        formatting.erb_format,
        formatting.markdownlint,
        formatting.prettierd.with {
          extra_filetypes = { "toml" },
          extra_args = { "--no-semi", "--single-quote", "--jsx-single-quote" },
        },
        formatting.sqlfluff.with({
          extra_args = { "--dialect", "mysql" }
        }),
        formatting.stylua,
        formatting.yamlfix
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

    -- if not null_ls.is_registered(coffee_fmt_query) then
    --   local coffee_fmt = {
    --     name = "coffee_fmt",
    --     method = null_ls.methods.FORMATTING,
    --     filetypes = { "coffee" },
    --     generator = null_ls.generator {
    --       command = "coffee-fmt",
    --       args = { "--write", "$FILENAME" },
    --     },
    --   }
    --
    --   null_ls.register(coffee_fmt)
    -- end
  end,
}

return M
