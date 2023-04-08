-- disable netrw at the very start of your init.lua (strongly advised)
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- set termguicolors to enable highlight groups
vim.opt.termguicolors = true

-- Set up nvim-cmp.
require("nvim-autopairs").setup {}

local cmp = require 'cmp'
local cmp_action = require('lsp-zero').cmp_action()

cmp.setup({
    mapping = cmp.mapping.preset.insert({
        ['<C-b>'] = cmp_action.luasnip_jump_backward(),
        ['<C-f>'] = cmp_action.luasnip_jump_forward(),
        ['<C-Space>'] = cmp.mapping.complete(),
        ['<C-e>'] = cmp.mapping.abort(),
        -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
        ['<CR>'] = cmp.mapping.confirm({select = true})
    }),
    sources = {
        {name = 'path', option = {trailing_slash = true}}, {name = 'nvim_lsp'},
        {name = 'buffer', keyword_length = 3},
        {name = 'luasnip', keyword_length = 2}
    }
})

-- Use buffer source for `/` and `?` (if you enabled `native_menu`, this won't work anymore).
cmp.setup.cmdline({'/', '?'}, {
    mapping = cmp.mapping.preset.cmdline(),
    sources = {{name = 'buffer'}}
})

-- Setup nvim-autopairs
local cmp_autopairs = require('nvim-autopairs.completion.cmp')
local npairs = require("nvim-autopairs")
local Rule = require('nvim-autopairs.rule')
local ts_conds = require('nvim-autopairs.ts-conds')

require('nvim-autopairs').setup()

cmp.event:on('confirm_done', cmp_autopairs.on_confirm_done())

npairs.setup({check_ts = true, fast_wrap = {}})

-- press % => %% only while inside a comment or string
npairs.add_rules({
    Rule("%", "%", "lua"):with_pair(ts_conds.is_ts_node({'string', 'comment'})),
    Rule("$", "$", "lua"):with_pair(ts_conds.is_not_ts_node({'function'}))
})

-- Set configuration for specific filetype.
cmp.setup.filetype('gitcommit', {
    sources = cmp.config.sources({
        {name = 'cmp_git'} -- You can specify the `cmp_git` source if you were installed it.
    }, {{name = 'buffer'}})
})

-- Use buffer source for `/` and `?` (if you enabled `native_menu`, this won't work anymore).
cmp.setup.cmdline({'/', '?'}, {
    mapping = cmp.mapping.preset.cmdline(),
    sources = {{name = 'buffer'}}
})

-- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
cmp.setup.cmdline(':', {
    mapping = cmp.mapping.preset.cmdline(),
    sources = cmp.config.sources({{name = 'path'}}, {{name = 'cmdline'}})
})

-- Mason and Mason-lspconfig setup
-- makes sure the language servers configured later with lspconfig are
-- actually available, and install them automatically if they're not
-- !! THIS MUST BE CALLED BEFORE ANY LANGUAGE SERVER CONFIGURATION
require("mason").setup({
    ui = {
        icons = {
            package_installed = "✓",
            package_pending = "➜",
            package_uninstalled = "✗"
        }
    }
})

require("mason-lspconfig").setup {
    -- automatically install language servers setup below for lspconfig
    automatic_installation = true
}

local lspz = require('lsp-zero').preset({})

lspz.on_attach(
    function(_, bufnr) lspz.default_keymaps({buffer = bufnr}) end)

lspz.format_mapping('gq', {
    format_opts = {async = false, timeout_ms = 10000},
    servers = {['null-ls'] = {'css', 'javascript', 'lua', 'ruby', 'scss'}}
})

lspz.set_sign_icons({error = '✘', warn = '▲', hint = '⚑', info = '»'})

-- lsp config
local servers = {
    coffeesense = {},
    cssls = {},
    cucumber_language_server = {},
    docker_compose_language_service = {},
    dockerls = {},
    eslint = {},
    html = {},
    lua_ls = lspz.nvim_lua_ls(),
    pyright = {},
    rubocop = {},
    solargraph = {},
    sqlls = {},
    stylelint_lsp = {},
    yamlls = {}
}

-- Actually setup the language servers so that they're available for our
-- LSP client, and enable language servers with the additional completion
-- capabilities offered by nvim-cmp
local nvim_lsp = require('lspconfig')
local capabilities = require('cmp_nvim_lsp').default_capabilities()

for lsp, opts in ipairs(servers) do
    nvim_lsp[lsp].setup(opts)
    nvim_lsp[lsp].setup({capabilities = capabilities})
end

lspz.setup()

-- lspconfig keybinds
-- Global mappings.
-- See `:help vim.diagnostic.*` for documentation on any of the below functions
vim.keymap.set('n', '<space>e', vim.diagnostic.open_float)
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev)
vim.keymap.set('n', ']d', vim.diagnostic.goto_next)
vim.keymap.set('n', '<space>q', vim.diagnostic.setloclist)

-- mason-null-ls.nvim setup
require("mason-null-ls").setup({
    automatic_installation = true,
    automatic_setup = true,
    ensure_installed = {
        "erb-lint", "eslint-lsp", "haml-lint", "jq", "jsonlint", "luacheck",
        "luaformatter", "marksman", "misspell", "pylint", "rubocop", "sqlfluff",
        "stylelint-lsp", "yamllint"
    }
})

local null_ls = require("null-ls")

null_ls.setup({
    sources = {
        -- code actions
        null_ls.builtins.code_actions.refactoring, -- completions
        null_ls.builtins.completion.spell, null_ls.builtins.completion.tags,
        -- diagnostics
        null_ls.builtins.diagnostics.codespell,
        null_ls.builtins.diagnostics.credo, null_ls.builtins.diagnostics.jshint,
        null_ls.builtins.diagnostics.luacheck,
        null_ls.builtins.diagnostics.tidy, null_ls.builtins.diagnostics.vint,
        null_ls.builtins.diagnostics.zsh, -- formatting
        null_ls.builtins.formatting.codespell,
        null_ls.builtins.formatting.erb_format,
        null_ls.builtins.formatting.htmlbeautifier,
        null_ls.builtins.formatting.mix,
        null_ls.builtins.formatting.prettier_eslint,
        null_ls.builtins.formatting.tidy,
        null_ls.builtins.formatting.trim_whitespace, -- hover
        null_ls.builtins.hover.dictionary, null_ls.builtins.hover.printenv
    }
})

require'mason-null-ls'.setup_handlers {
    function(source_name, methods)
        -- all sources with no handler get passed here

        -- To keep the original functionality of `automatic_setup = true`,
        -- please add the below.
        require("mason-null-ls.automatic_setup")(source_name, methods)
    end,
    stylua = function(source_name, methods)
        null_ls.register(null_ls.builtins.formatting.stylua)
    end
}

-- Setup Commenter
require('comment').setup()

-- Nvim Tree Setup
-- empty setup using defaults
require("nvim-tree").setup({filters = {dotfiles = true}})

-- Setup nvim-treesitter
require'nvim-treesitter.configs'.setup {
    autotag = {enable = true},
    endwise = {enable = true},
    -- A list of parser names, or "all"
    ensure_installed = {
        "css", "comment", "dockerfile", "elixir", "gitattributes", "gitignore",
        "html", "http", "javascript", "json", "lua", "markdown", "python",
        "regex", "ruby", "scss", "vim", "yaml"
    },

    -- Install parsers synchronously (only applied to `ensure_installed`)
    sync_install = false,

    -- Automatically install missing parsers when entering buffer
    auto_install = true,

    -- List of parsers to ignore installing (for "all")
    ignore_install = {},

    -- If you need to change the installation directory of the parsers (see -> Advanced Setup)
    -- parser_install_dir = "/some/path/to/store/parsers",
    -- Remember to run vim.opt.runtimepath:append("/some/path/to/store/parsers")!

    highlight = {
        -- `false` will disable the whole extension
        enable = true,

        -- NOTE: these are the names of the parsers and not the filetype. (for example if you want to
        -- disable highlighting for the `tex` filetype, you need to include `latex` in this list as this is
        -- the name of the parser)
        -- list of language that will be disabled
        disable = {},

        -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
        -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
        -- Using this option may slow down your editor, and you may see some duplicate highlights.
        -- Instead of true it can also be a list of languages
        additional_vim_regex_highlighting = false
    },
    refactor = {
        highlight_current_scope = {enable = true},
        highlight_definitions = {enable = true, clear_on_cursor_move = true},
        smart_rename = {
            enable = true,
            -- Assign keymaps to false to disable them, e.g. `smart_rename = false`.
            keymaps = {smart_rename = "grr"}
        }
    }
}

-- Mix setup
require("mix").setup()

-- Scrollbar setup
require("scrollbar").setup()

-- Telescope and Telescope-fzf-native setup
require('telescope').setup {defaults = {file_ignore_patterns = {"vendor"}}}

-- To get fzf loaded and working with telescope, you need to call
-- load_extension, somewhere after setup function:
require('telescope').load_extension('fzf')

-- Lualine setup
require('lualine').setup {
    options = {
        icons_enabled = true,
        theme = 'dracula',
        component_separators = {left = '', right = ''},
        section_separators = {left = '', right = ''},
        disabled_filetypes = {statusline = {}, winbar = {}},
        ignore_focus = {},
        always_divide_middle = true,
        globalstatus = false,
        refresh = {statusline = 1000, tabline = 1000, winbar = 1000}
    },
    sections = {
        lualine_a = {'mode'},
        lualine_b = {'branch', 'diff', 'diagnostics'},
        lualine_c = {'filename'},
        lualine_x = {'encoding', 'fileformat', 'filetype'},
        lualine_y = {'progress'},
        lualine_z = {'location'}
    },
    inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = {'filename'},
        lualine_x = {'location'},
        lualine_y = {},
        lualine_z = {}
    },
    tabline = {},
    winbar = {},
    inactive_winbar = {},
    extensions = {'fugitive', 'fzf', 'nvim-tree'}
}

-- Setup nvim tree refactoring
require('refactoring').setup({})

-- load refactoring Telescope extension
require("telescope").load_extension("refactoring")

-- remap to open the Telescope refactoring menu in visual mode
vim.api.nvim_set_keymap("v", "<leader>rr",
                        "<Esc><cmd>lua require('telescope').extensions.refactoring.refactors()<CR>",
                        {noremap = true})
