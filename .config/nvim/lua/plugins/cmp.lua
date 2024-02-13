local M = {
  "hrsh7th/nvim-cmp",
  commit = "d3a3056204e1a9dbb7c7fe36c114dc43b681768c",
  dependencies = {
    {
      "hrsh7th/cmp-buffer",
      commit = "3022dbc9166796b644a841a02de8dd1cc1d311fa",
      event = "InsertEnter",
    },
    {
      "hrsh7th/cmp-calc",
      event = "InsertEnter",
    },
    {
      "hrsh7th/cmp-cmdline",
      commit = "8ee981b4a91f536f52add291594e89fb6645e451",
      event = "InsertEnter",
    },
    {
      "hrsh7th/cmp-emoji",
      event = "InsertEnter",
      commit = "19075c36d5820253d32e2478b6aaf3734aeaafa0",
    },
    {
      "garyhurtz/cmp_kitty",
      event = "InsertEnter",
    },
    {
      "saadparwaiz1/cmp_luasnip",
      commit = "05a9ab28b53f71d1aece421ef32fee2cb857a843",
      event = "InsertEnter",
    },
    {
      "hrsh7th/cmp-nvim-lsp",
      commit = "44b16d11215dce86f253ce0c30949813c0a90765",
      event = "InsertEnter",
    },
    {
      "hrsh7th/cmp-nvim-lua",
      commit = "f12408bdb54c39c23e67cab726264c10db33ada8",
      event = "InsertEnter",
    },
    {
      "hrsh7th/cmp-path",
      commit = "91ff86cd9c29299a64f968ebb45846c485725f23",
      event = "InsertEnter",
    },
    {
      "ray-x/cmp-treesitter",
      event = "InsertEnter",
    },
    {
      "L3MON4D3/LuaSnip",
      commit = "80a8528f084a97b624ae443a6f50ff8074ba486b",
      event = "InsertEnter",
      dependencies = {
        "rafamadriz/friendly-snippets",
      },
    },
  },
  event = {
    "InsertEnter",
  },
}

function M.config()
  local cmp = require "cmp"
  local luasnip = require "luasnip"
  require("luasnip/loaders/from_vscode").lazy_load()

  vim.api.nvim_set_hl(0, "CmpItemKindCopilot", { fg = "#6CC644" })
  vim.api.nvim_set_hl(0, "CmpItemKindCrate", { fg = "#F64D00" })
  vim.api.nvim_set_hl(0, "CmpItemKindEmoji", { fg = "#FDE030" })

  local check_backspace = function()
    local col = vim.fn.col "." - 1
    return col == 0 or vim.fn.getline("."):sub(col, col):match "%s"
  end

  local icons = require "utils.icons"

  cmp.setup {
    confirm_opts = {
      behavior = cmp.ConfirmBehavior.Replace,
      select = false,
    },
    experimental = {
      ghost_text = true,
    },
    formatting = {
      fields = { "kind", "abbr", "menu" },
      format = function(entry, vim_item)
        vim_item.kind = icons.kind[vim_item.kind]
        vim_item.menu = ({
          nvim_lsp = "",
          nvim_lua = "",
          luasnip = "",
          buffer = "",
          path = "",
          emoji = "",
        })[entry.source.name]

        if entry.source.name == "copilot" then
          vim_item.kind = icons.git.Octoface
          vim_item.kind_hl_group = "CmpItemKindCopilot"
        end

        if entry.source.name == "crates" then
          vim_item.kind = icons.misc.Package
          vim_item.kind_hl_group = "CmpItemKindCrate"
        end

        if entry.source.name == "lab.quick_data" then
          vim_item.kind = icons.misc.CircuitBoard
          vim_item.kind_hl_group = "CmpItemKindConstant"
        end

        if entry.source.name == "emoji" then
          vim_item.kind = icons.misc.Smiley
          vim_item.kind_hl_group = "CmpItemKindEmoji"
        end

        return vim_item
      end,
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
        if cmp.visible() then
          cmp.select_next_item()
        elseif luasnip.expandable() then
          luasnip.expand()
        elseif luasnip.expand_or_jumpable() then
          luasnip.expand_or_jump()
        elseif check_backspace() then
          fallback()
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
        elseif luasnip.jumpable(-1) then
          luasnip.jump(-1)
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
        luasnip.lsp_expand(args.body) -- For `luasnip` users.
      end,
    },
    sources = {
      { name = "buffer" },
      { name = "calc" },
      { name = "emoji" },
      { name = "kitty" },
      { name = "luasnip" },
      { name = "nvim_lsp" },
      { name = "nvim_lua" },
      { name = "path" },
      { name = "treesitter" },
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

  pcall(function()
    local function on_confirm_done(...)
      require("nvim-autopairs.completion.cmp").on_confirm_done()(...)
    end

    require("cmp").event:off("confirm_done", on_confirm_done)
    require("cmp").event:on("confirm_done", on_confirm_done)
  end)
end

return M
