-- LSP: mason, mason-lspconfig, lazydev
-- Uses Neovim 0.12 native vim.lsp.config / vim.lsp.enable

-- Lazydev (Neovim Lua API completions) - must be set up before LSP
require("lazydev").setup({
  library = {
    { path = "${3rd}/luv/library", words = { "vim%.uv" } },
  },
})

-- Mason (LSP/tool installer)
require("mason").setup()

-- Mason-lspconfig (ensures servers are installed)
require("mason-lspconfig").setup({
  ensure_installed = {
    "lua_ls",
    "ts_ls",
    "pyright",
    "html",
    "cssls",
    "jsonls",
    "yamlls",
  },
})

-- Merge blink.cmp capabilities
local capabilities = vim.lsp.protocol.make_client_capabilities()
local ok, blink = pcall(require, "blink.cmp")
if ok then
  capabilities = blink.get_lsp_capabilities(capabilities)
end

-- Configure LSP servers via vim.lsp.config (Neovim 0.12+)
vim.lsp.config("*", {
  capabilities = capabilities,
})

vim.lsp.config("lua_ls", {
  settings = {
    Lua = {
      workspace = { checkThirdParty = false },
      codeLens = { enable = true },
      completion = { callSnippet = "Replace" },
      diagnostics = { globals = { "vim", "Snacks" } },
    },
  },
})

-- Enable all configured servers
vim.lsp.enable({
  "lua_ls",
  "ts_ls",
  "pyright",
  "html",
  "cssls",
  "jsonls",
  "yamlls",
})

-- LspAttach: buffer-local keymaps using Snacks pickers
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("bvim_lsp_attach", { clear = true }),
  callback = function(ev)
    local buf = ev.buf
    local opts = { buffer = buf }

    vim.keymap.set("n", "gd", function() Snacks.picker.lsp_definitions() end, vim.tbl_extend("force", opts, { desc = "Goto Definition" }))
    vim.keymap.set("n", "gr", function() Snacks.picker.lsp_references() end, vim.tbl_extend("force", opts, { nowait = true, desc = "References" }))
    vim.keymap.set("n", "gI", function() Snacks.picker.lsp_implementations() end, vim.tbl_extend("force", opts, { desc = "Goto Implementation" }))
    vim.keymap.set("n", "gy", function() Snacks.picker.lsp_type_definitions() end, vim.tbl_extend("force", opts, { desc = "Goto Type Definition" }))
  end,
})
