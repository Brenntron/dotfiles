local M = {
  "neovim/nvim-lspconfig",
  commit = "649137cbc53a044bffde36294ce3160cb18f32c7",
  lazy = false,
  event = { "BufReadPre" },
  dependencies = {
    {
      "folke/neodev.nvim",
       commit = "b094a663ccb71733543d8254b988e6bebdbdaca4",
    },
    {
      "hrsh7th/cmp-nvim-lsp",
      commit = "0e6b2ed705ddcff9738ec4ea838141654f12eeef",
    },
    "tamago324/nlsp-settings.nvim",
    "williambowman/mason-lspconfig.nvim",
  },
}

function M.config()
  local function common_capabilities()
    local status_ok, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
    if status_ok then
      return cmp_nvim_lsp.default_capabilities()
    end

    local capabilities = vim.lsp.protocol.make_client_capabilities()
    capabilities.textDocument.completion.completionItem.snippetSupport = true
    capabilities.textDocument.completion.completionItem.resolveSupport = {
      properties = {
        "documentation",
        "detail",
        "additionalTextEdits",
      },
    }
  end
  local diagnostics_icons = require("utils.icons").diagnostics
  local lspconfig = require "lspconfig"

  local servers = require("utils.servers")

  local default_diagnostic_config = {
    float = {
      focusable = false,
      style = "minimal",
      border = "rounded",
      source = "always",
      header = "",
      prefix = "",
      suffix = "",
    },
    severity_sort = true,
    -- show signs
    signs = {
      active = true,
      valus = {
        { name = "DiagnosticsSignError", text = diagnostics_icons.Error },
        { name = "DiagnosticsSignWarn", text = diagnostics_icons.Warning },
        { name = "DiagnosticsSignHint", text = diagnostics_icons.Hint },
        { name = "DiagnosticsSignInfo", text = diagnostics_icons.Information },
      },
    },
    underline = true,
    update_in_insert = true,
    -- disable virtual text
    virtual_text = false,
  }

  vim.diagnostic.config(default_diagnostic_config)

  for _, sign in ipairs(vim.tbl_get(vim.diagnostic.config(), "signs", "values") or {}) do
    vim.fn.sign_define(sign.name, { texthl = sign.name, text = sign.text, numhl = sign.name })
  end

  vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
    border = "rounded",
  })

  vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, {
    border = "rounded",
  })

  require("lspconfig.ui.windows").default_options_border = "rounded"

  for _, server in ipairs(servers) do
    local opts = {
      on_attach = on_attach,
      capabilities = common_capabilities(),
    }

    local require_ok, settings = pcall(require, "lspsettings." .. server)

    if require_ok then
      opts = vim.tbl_deep_extend("force", settings, opts)
    end

    if server == "lua_ls" then
      require("neodev").setup {}
    end

    lspconfig[server].setup(opts)
  end

  -- Setup coffeesense as it is not included in mason-lspconfig
  local coffeesense_opts = {
    on_attach = on_attach,
    capabilities = common_capabilities(),
  }
  local require_ok, settings = pcall(require, "lspsettings.coffeesense")

  if require_ok then
    coffeesense_opts = vim.tbl_deep_extend("force", settings, coffeesense_opts)
  end

  lspconfig.coffeesense.setup(coffeesense_opts)
end

return M
