local M = {
  "neovim/nvim-lspconfig",
  commit = "649137cbc53a044bffde36294ce3160cb18f32c7",
  lazy = false,
  event = { "BufReadPre" },
  dependencies = {
    {
      "folke/neodev.nvim",
    },
    { "SmiteshP/nvim-navic" }
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

  local function on_attach(client, bufnr)
    if client.server_capabilities.documentSymbolProvider then
      local status_ok, navic = pcall(require, "nvim-navic")
      if status_ok then
        return navic.attach(client, bufnr)
      end
    end
  end

  local diagnostics_icons = require("utils.icons").diagnostics
  local lspconfig = require "lspconfig"

  local servers = require("utils.servers").server_list

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
    -- virtual_text = false,
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

  local opts = {
    capabilities = common_capabilities(),
    on_attach = on_attach
  }

  for _, server in ipairs(servers) do

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
  local coffeesense_opts = opts
  local coffee_require_ok, coffee_settings = pcall(require, "lspsettings.coffeesense")

  if coffee_require_ok then
    coffeesense_opts = vim.tbl_deep_extend("force", coffee_settings, coffeesense_opts)
  end

  lspconfig.coffeesense.setup(coffeesense_opts)

  -- Setup cucumber_language_server with a forked ls.
  local cucumber_language_server_opts = opts
  local cucumber_require_ok, cucumber_settings = pcall(require, "lspsettings.cucumber_language_server")

  if cucumber_require_ok then
    cucumber_language_server_opts = vim.tbl_deep_extend("force", cucumber_settings, cucumber_language_server_opts)
  end

  lspconfig.cucumber_language_server.setup(cucumber_language_server_opts)

  -- gramarly setup require nodejs 16
  -- local grammarly_opts = opts
  -- local grammarly_require_ok, grammarly_settings = pcall(require, "lspsettings.grammarly")
  --
  -- if grammarly_require_ok then
  --   grammarly_opts = vim.tbl_deep_extend("force", grammarly_settings, grammarly_opts)
  -- end
  --
  -- lspconfig.grammarly.setup(grammarly_opts)
end

return M
