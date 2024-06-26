local M = {
  "hrsh7th/nvim-cmp",
  dependencies = {
    {
      "hrsh7th/cmp-buffer",
      event = { "InsertEnter", "LspAttach" },
    },
    {
      "hrsh7th/cmp-calc",
      event = { "InsertEnter", "LspAttach" },
    },
    {
      "zbirenbaum/copilot-cmp",
      event = { "InsertEnter", "LspAttach" },
      config = function()
        require("copilot_cmp").setup({
          fix_pairs = true,
        })
      end,
    },
    {
      "hrsh7th/cmp-cmdline",
      event = "InsertEnter",
    },
    {
      "hrsh7th/cmp-emoji",
      event = { "InsertEnter", "LspAttach" },
    },
    {
      "garyhurtz/cmp_kitty",
      event = { "InsertEnter", "LspAttach" },
      init = function()
        require("cmp_kitty"):setup()
      end,
    },
    {
      "rcarriga/cmp-dap",
      event = { "InsertEnter", "LspAttach" },
    },
    {
      "saadparwaiz1/cmp_luasnip",
      event = { "InsertEnter", "LspAttach" },
    },
    {
      "hrsh7th/cmp-nvim-lsp",
      event = { "InsertEnter", "LspAttach" },
    },
    {
      "hrsh7th/cmp-nvim-lua",
      event = { "InsertEnter", "LspAttach" },
    },
    {
      "hrsh7th/cmp-path",
      event = { "InsertEnter", "LspAttach" },
    },
    {
      "ray-x/cmp-treesitter",
      event = { "InsertEnter", "LspAttach" },
    },
    {
      "onsails/lspkind.nvim",
      event = { "InsertEnter", "LspAttach" },
    },
    {
      "windwp/nvim-autopairs",
      event = "InsertEnter",
    },
  },
  event = { "InsertEnter", "LspAttach" },
}

function M.config()
  local cmp = require "cmp"
  local autopoairs_rule = require "nvim-autopairs.rule"
  local cmp_autopairs = require 'nvim-autopairs.completion.cmp'
  local ts_conds = require 'nvim-autopairs.ts-conds'
  local autopairs = require 'nvim-autopairs'
  local Rule = require 'nvim-autopairs.rule'
  local icons = require "utils.icons"
  local lspkind = require "lspkind"

  local check_backspace = function()
    local col = vim.fn.col "." - 1
    return col == 0 or vim.fn.getline("."):sub(col, col):match "%s"
  end

  local has_words_before = function()
    if vim.api.nvim_buf_get_option(0, "buftype") == "prompt" then return false end
    local line, col = unpack(vim.api.nvim_win_get_cursor(0))
    return col ~= 0 and vim.api.nvim_buf_get_text(0, line-1, 0, line-1, col, {})[1]:match("^%s*$") == nil
  end

  cmp.setup {
    confirm_opts = {
      behavior = cmp.ConfirmBehavior.Replace,
      select = false,
    },
    enabled = function()
      return vim.api.nvim_buf_get_option(0, "buftype") ~= "prompt"
        or require("cmp_dap").is_dap_buffer()
    end,
    experimental = {
      ghost_text = true,
    },
    formatting = {
      fields = { "kind", "abbr", "menu" },
      format = lspkind.cmp_format({
        mod = 'symbol',
        maxwidth = 50,
        ellipsis_char = '...',
        showlabelDetails = true,
        symbol_map = { Copilot = " " },

        function(entry, vim_item)
          vim_item.kind = icons.kind[vim_item.kind]
          vim_item.menu = ({
            nvim_lsp = "",
            nvim_lua = "",
            buffer = "",
            path = "",
            emoji = "",
          })[entry.source.name]

          if entry.source.name == "copilot" then
            vim_item.kind = icons.git.Octoface
            vim_item.kind_hl_group = "CmpItemKindCopilot"
          end

          if entry.source.name == "emoji" then
            vim_item.kind = icons.misc.Smiley
            vim_item.kind_hl_group = "CmpItemKindEmoji"
          end

          if entry.source.name == "crates" then
            vim_item.kind = icons.misc.Package
            vim_item.kind_hl_group = "CmpItemKindCrate"
          end

          if entry.source.name == "lab.quick_data" then
            vim_item.kind = icons.misc.CircuitBoard
            vim_item.kind_hl_group = "CmpItemKindConstant"
          end

          return vim_item
        end,
      })
    },
    mapping = cmp.mapping.preset.insert {
      ["<C-k>"] = cmp.mapping(cmp.mapping.select_prev_item(), { "i", "c" }),
      ["<C-j>"] = cmp.mapping(cmp.mapping.select_next_item(), { "i", "c" }),
      ["<Down>"] = cmp.mapping(cmp.mapping.select_next_item(), { "i", "c" }),
      ["<Up>"] = cmp.mapping(cmp.mapping.select_prev_item(), { "i", "c" }),
      ["<C-b>"] = cmp.mapping(cmp.mapping.scroll_docs(-1), { "i", "c" }),
      ["<C-f>"] = cmp.mapping(cmp.mapping.scroll_docs(1), { "i", "c" }),
      ["<C-Space>"] = cmp.mapping(cmp.mapping.complete(), { "i", "c" }),
      ["<C-e>"] = cmp.mapping {
        i = cmp.mapping.abort(),
        c = cmp.mapping.close(),
      },
      -- Accept currently selected item. If none selected, `select` first item.
      -- Set `select` to `false` to only confirm explicitly selected items.
      ["<CR>"] = cmp.mapping.confirm { select = true },
      ["<Tab>"] = cmp.mapping(function(fallback)
        if cmp.visible() and has_words_before() then
          cmp.select_next_item({ behavior = cmp.SelectBehavior.Select })
        elseif cmp.visible() then
          cmp.select_next_item()
        else
          fallback()
        end
      end, {
        "i",
        "s",
      }),
      ["<S-Tab>"] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.select_prev_item()
        else
          fallback()
        end
      end, {
        "i",
        "s",
      }),
    },
    snippet = {
      expand = function(args)
        require("luasnip").lsp_expand(args.body)
      end,
    },
    sorting = {
      priority_weight = 2,
      comparators = {
        require("copilot_cmp.comparators").prioritize,
        -- Below is the default comparitor list and order for nvim-cmp
        cmp.config.compare.offset,
        -- cmp.config.compare.scopes, -- this is commented in nvim-cmp too
        cmp.config.compare.exact,
        cmp.config.compare.score,
        cmp.config.compare.recently_used,
        cmp.config.compare.locality,
        cmp.config.compare.kind,
        cmp.config.compare.sort_text,
        cmp.config.compare.length,
        cmp.config.compare.order,
      },
    },
    sources = {
      { name = "buffer", group_index = 2 },
      { name = "calc", group_index = 2 },
      { name = "copilot", group_index = 2 },
      { name = "emoji", group_index = 2 },
      { name = "kitty", group_index = 2 },
      { name = "luasnip", group_index = 2},
      { name = "nvim_lsp", group_index = 2 },
      { name = "nvim_lua", group_index = 2 },
      { name = "path", group_index = 2 },
      { name = "treesitter", group_index = 2 },
    },
    window = {
      completion = {
        border = "rounded",
        col_offset = -3,
        scrollbar = false,
        scrolloff = 8,
        side_padding = 1,
        winhighlight = "Normal:Pmenu,CursorLine:PmenuSel,FloatBorder:FloatBorder,Search:None",
      },
      documentation = {
        border = "rounded",
        winhighlight = "Normal:Pmenu,FloatBorder:FloatBorder,Search:None",
      },
    },
  }

    -- `/` cmdline setup.
  cmp.setup.cmdline('/', {
    mapping = cmp.mapping.preset.cmdline(),
    sources = {
      { name = 'buffer' }
    }
  })

  -- `:` cmdline setup.
  cmp.setup.cmdline(':', {
    mapping = cmp.mapping.preset.cmdline(),
    sources = cmp.config.sources({
      { name = 'path' }
    }, {
      {
        name = 'cmdline',
        option = {
          ignore_cmds = { 'Man', '!' }
        }
      }
    })
  })

  -- DAP setup
  cmp.setup.filetype({ "dap-repl"}, { source = { name = "dap" }})

  -- Autopairs setup
  autopairs.setup({
    check_ts = true,
    ts_config = {
      lua = {'string'}, -- it will not add pair on that treesitter node
      javascript = {'template_string'},
    }
  })

  autopairs.add_rules({
    Rule("%", "%", "lua")
      :with_pair(ts_conds.is_ts_node({'string', 'comment'})),
    Rule("$", "$", "lua")
      :with_pair(ts_conds.is_not_ts_node({'function'}))
  })

  cmp.event:off("confirm_done", cmp_autopairs.on_confirm_done())
  cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
end

return M
