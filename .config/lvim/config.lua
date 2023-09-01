--[[
lvim is the global options object

Linters should be
filled in as strings with either
a global executable or a path to
an executable
]] -- THESE ARE EXAMPLE CONFIGS FEEL FREE TO CHANGE TO WHATEVER YOU WANT
-- general
lvim.log.level = "warn"
lvim.format_on_save.enabled = false
-- lvim.colorscheme = "tokyonight"

-- Change theme settings
lvim.builtin.theme.tokyonight.options.dim_inactive = true
lvim.builtin.theme.tokyonight.options.style = "moon"
--
-- to disable icons and use a minimalist setup, uncomment the following
-- lvim.use_icons = false

-- keymappings [view all the defaults by pressing <leader>Lk]
lvim.leader = "space"
-- add your own keymapping
lvim.keys.normal_mode["<C-s>"] = ":w<cr>"
-- lvim.keys.normal_mode["<S-l>"] = ":BufferLineCycleNext<CR>"
-- lvim.keys.normal_mode["<S-h>"] = ":BufferLineCyclePrev<CR>"
-- unmap a default keymapping
-- vim.keymap.del("n", "<C-Up>")
-- override a default keymapping
-- lvim.keys.normal_mode["<C-q>"] = ":q<cr>" -- or vim.keymap.set("n", "<C-q>", ":q<cr>" )

-- Change Telescope navigation to use j and k for navigation and n and p for history in both input and normal mode.
-- we use protected-mode (pcall) just in case the plugin wasn't loaded yet.
local _, actions = pcall(require, "telescope.actions")
lvim.builtin.telescope.defaults.mappings = {
    -- for input mode
    i = {
        ["<C-j>"] = actions.move_selection_next,
        ["<C-k>"] = actions.move_selection_previous,
        ["<C-n>"] = actions.cycle_history_next,
        ["<C-p>"] = actions.cycle_history_prev
    },
    -- for normal mode
    n = {
        ["<C-j>"] = actions.move_selection_next,
        ["<C-k>"] = actions.move_selection_previous
    }
}

-- Telescope ignore list
lvim.builtin.telescope.defaults.file_ignore_patterns = {
    "vendor/*", "%.lock", "%.sqlite3", "node_modules/*", "%.jpg", "%.jpeg",
    "%.png", "%.svg", "%.otf", "%.ttf", ".git/", ".github/", ".idea/",
    ".settings/", "build/", "env/", "node_modules/", "%.cache", "%.ico",
    "%.pdf", "%.dylib", "%.jar"
}

-- Use which-key to add extra bindings with the leader-key prefix
lvim.builtin.which_key.mappings["P"] = {
    "<cmd>Telescope projects<CR>", "Projects"
}

lvim.builtin.which_key.mappings["t"] = {
    name = "+Trouble",
    r = {"<cmd>Trouble lsp_references<cr>", "References"},
    f = {"<cmd>Trouble lsp_definitions<cr>", "Definitions"},
    d = {"<cmd>Trouble document_diagnostics<cr>", "Diagnostics"},
    q = {"<cmd>Trouble quickfix<cr>", "QuickFix"},
    l = {"<cmd>Trouble loclist<cr>", "LocationList"},
    w = {"<cmd>Trouble workspace_diagnostics<cr>", "Workspace Diagnostics"}
}

-- Spectre keybinds
lvim.builtin.which_key.mappings['S'] = {
    '<cmd>lua require("spectre").open()<CR>', "Open Spectre"
}
lvim.builtin.which_key.mappings['sw'] = {
    '<cmd>lua require("spectre").open_visual({select_word=true})<CR>',
    "Search current word"
}
lvim.builtin.which_key.mappings['sp'] = {
    '<cmd>lua require("spectre").open_file_search({select_word=true})<CR>',
    "Search on current file"
}

-- vim-easy-align keybinds
lvim.keys.normal_mode["ga"] = "<Plug>(EasyAlign)"
lvim.keys.visual_mode["ga"] = "<Plug>(EasyAlign)"

-- Additional Plugins
lvim.plugins = {
    {
        "cappyzawa/trim.nvim",
        event = "BufRead",
        config = function()
            require('trim').setup({trim_last_line = false})
        end
    }, {'edluffy/hologram.nvim', auto_display = true}, {"fladson/vim-kitty"}, {
        "folke/neodev.nvim",
        config = function()
            require('neodev').setup({
                library = {plugins = {"neotest"}, types = true}
            })
        end
    }, {
        "folke/trouble.nvim",
        cmd = "TroubleToggle",
        requires = "nvim-tree/nvim-web-devicons",
        config = function() require("trouble").setup {} end
    }, {'kchmck/vim-coffee-script'},
    {"kristijanhusak/vim-dadbod-completion", requires = "tpope/vim-dadbod"},
    {"kristijanhusak/vim-dadbod-ui", requires = "tpope/vim-dadbod"},
    {'junegunn/vim-easy-align'}, {'Mofiqul/dracula.nvim'}, {
        "nvim-neotest/neotest",
        requires = {
            "nvim-lua/plenary.nvim", "nvim-treesitter/nvim-treesitter",
            "antoinemadec/FixCursorHold.nvim"
        },
        config = {
            function()
                require("neotest").setup({
                    adapters = {
                        require("neotest-plenary"),
                        require("neotest-vim-test")(
                            {ignore_file_types = {"vim"}})
                    }
                })
            end
        }
    }, {
        'nvim-neotest/neotest-plenary',
        config = function() require("neotest-plenary").setup({}) end
    }, {"nvim-neotest/neotest-vim-test", requires = {"vim-test/vim-test"}},
    {
        "nvim-telescope/telescope-fzy-native.nvim",
        run = "make",
        event = "BufRead"
    }, {
        "nvim-telescope/telescope-project.nvim",
        event = "BufWinEnter",
        setup = function() vim.cmd [[packadd telescope.nvim]] end
    }, {
        "ray-x/lsp_signature.nvim",
        event = "BufRead",
        config = function() require"lsp_signature".on_attach() end
    }, {
        "rmagatti/goto-preview",
        config = function()
            require('goto-preview').setup {
                width = 120, -- Width of the floating window
                height = 25, -- Height of the floating window
                default_mappings = false, -- Bind default mappings
                debug = false, -- Print debug information
                opacity = nil, -- 0-100 opacity level of the floating window where 100 is fully transparent.
                post_open_hook = nil -- A function taking two arguments, a buffer and a window to be ran as a hook.
                -- You can use "default_mappings = true" setup option
                -- Or explicitly set keybindings
                -- vim.cmd("nnoremap gpd <cmd>lua require('goto-preview').goto_preview_definition()<CR>")
                -- vim.cmd("nnoremap gpi <cmd>lua require('goto-preview').goto_preview_implementation()<CR>")
                -- vim.cmd("nnoremap gP <cmd>lua require('goto-preview').close_all_win()<CR>")
            }
        end
    }, {"sindrets/diffview.nvim", event = "BufRead"}, {
        "simrat39/symbols-outline.nvim",
        config = function() require('symbols-outline').setup() end
    }, {
        "windwp/nvim-spectre",
        event = "BufRead",
        config = function() require("spectre").setup() end
    }, {
        "windwp/nvim-ts-autotag",
        config = function()
            require("nvim-ts-autotag").setup({
                autotag = {enable = true},
                filetypes = {
                    "html", "embedded_template", "eruby", 'javascript',
                    'markdown', 'php', 'svelte', 'typescript', 'vue', 'xml'
                }
            })
        end
    }
}

-- After changing plugin config exit and reopen LunarVim, Run :PackerInstall :PackerCompile
lvim.builtin.alpha.active = true
lvim.builtin.alpha.mode = "dashboard"
lvim.builtin.terminal.active = true
lvim.builtin.nvimtree.setup.view.side = "left"
lvim.builtin.nvimtree.setup.renderer.icons.show.git = false
lvim.builtin.treesitter.autotag.enable = true
lvim.builtin.treesitter.matchup.enable = true

-- Hologram setup
require('hologram').setup {
    auto_display = true -- WIP automatic markdown image display, may be prone to breaking
}

-- if you don't want all the parsers change this to a table of the ones you want
lvim.builtin.treesitter.ensure_installed = {
    "bash", "comment", "css", "dockerfile", "dot", "eex", "elixir",
    "git_rebase", "gitignore", "html", "javascript", "json", "lua",
    "markdown_inline", "python", "regex", "ruby", "rust", "scss", "sql", "vim",
    "yaml"
}

lvim.builtin.treesitter.ignore_install = {"haskell"}
lvim.builtin.treesitter.highlight.enable = true

-- Mason setup
require("mason").setup()

-- Add additional languages
require("mason-lspconfig").setup({
    ensure_installed = {
        "bashls", "cssls", "cucumber_language_server", "dockerls", "grammarly",
        "html", "jsonls", "marksman", "pyright", "pylsp", "solargraph", "sqlls",
        "yamlls"
    }
})

-- -- Coffeesense Setup
require'lspconfig'.coffeesense.setup {}

-- Telescope plugin update
lvim.builtin.telescope.on_config_done = function(telescope)
    pcall(telescope.load_extension, "fzy_native")
    -- any other extensions loading
end

-- linter and formatter setup for null-ls
local formatters = require "lvim.lsp.null-ls.formatters"
local linters = require "lvim.lsp.null-ls.linters"

formatters.setup {
    {name = 'beautysh'}, {name = "erb_lint"}, {name = "lua_format"},
    {name = "markdownlint"}, {name = 'prettierd'}, {name = "rubocop"},
    {name = 'stylelint'}
}

linters.setup {
    {name = "codespell", filetypes = {"erb", "eruby", "html", "markdown"}},
    {command = "shellcheck", extra_args = {"--severity", "warning"}},
    {name = "zsh", filetypes = {"zsh"}}
}

-- Extend format timeout
lvim.builtin.which_key.mappings["l"]["f"] = {
    function() require("lvim.lsp.utils").format {timeout_ms = 5000} end,
    "Format"
}

-- generic options
vim.opt.clipboard = "unnamedplus" -- allows neovim to access the system clipboard
vim.opt.tabstop = 2 -- insert 2 spaces for a tab
vim.opt.relativenumber = true -- set relative numbered lines

-- add filetypes
vim.filetype.add {extension = {coffee = 'coffee'}, {config = 'conf'}}

-- generic LSP settings

-- make sure server will always be installed even if the server is in skipped_servers list
-- lvim.lsp.installer.setup.ensure_installed = {"sumneko_lua", "jsonls"}
-- change UI setting of `LspInstallInfo`
-- see <https://github.com/williamboman/nvim-lsp-installer#default-configuration>
-- lvim.lsp.installer.setup.ui.check_outdated_servers_on_open = false
-- lvim.lsp.installer.setup.ui.border = "rounded"
-- lvim.lsp.installer.setup.ui.keymaps = {
--     uninstall_server = "d",
--     toggle_server_expand = "o"
-- }

---@usage disable automatic installation of servers
-- lvim.lsp.installer.setup.automatic_installation = false

-- ---configure a server manually. !!Requires `:LvimCacheReset` to take effect!!
-- ---see the full default list `:lua print(vim.inspect(lvim.lsp.automatic_configuration.skipped_servers))`
-- vim.list_extend(lvim.lsp.automatic_configuration.skipped_servers, { "pyright" })
-- local opts = {} -- check the lspconfig documentation for a list of all possible options
-- require("lvim.lsp.manager").setup("pyright", opts)

-- ---remove a server from the skipped list, e.g. eslint, or emmet_ls. !!Requires `:LvimCacheReset` to take effect!!
-- ---`:LvimInfo` lists which server(s) are skipped for the current filetype
-- lvim.lsp.automatic_configuration.skipped_servers = vim.tbl_filter(function(server)
--   return server ~= "emmet_ls"
-- end, lvim.lsp.automatic_configuration.skipped_servers)

-- -- you can set a custom on_attach function that will be used for all the language servers
-- -- See <https://github.com/neovim/nvim-lspconfig#keybindings-and-completion>
-- lvim.lsp.on_attach_callback = function(client, bufnr)
--   local function buf_set_option(...)
--     vim.api.nvim_buf_set_option(bufnr, ...)
--   end
--   --Enable completion triggered by <c-x><c-o>
--   buf_set_option("omnifunc", "v:lua.vim.lsp.omnifunc")
-- end

-- Autocommands (https://neovim.io/doc/user/autocmd.html)
-- vim.api.nvim_create_autocmd("BufEnter", {
--   pattern = { "*.json", "*.jsonc" },
--   -- enable wrap mode for json files only
--   command = "setlocal wrap",
-- })
