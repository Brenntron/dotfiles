local M = {}

M.server_list = {
  "bashls",
  "cssls",
  "cssmodules_ls",
  -- "cucumber_language_server", main distrobution of cls is broken
  "eslint",
  "dockerls",
  "docker_compose_language_service",
  "html",
  "jsonls",
  "lua_ls",
  "marksman",
  -- "rubocop", # lspconfig does not recognize this configuration
  "solargraph",
  -- "somesass_ls", # lspconfig does not recognize this configuration
  "sqlls",
  "stylelint_lsp",
  "tsserver",
  -- "typos_lsp", # lspconfig does not recognize this configuration
  "volar",
  "yamlls",
}

return M
