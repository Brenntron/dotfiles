local M = {
  -- "Mofiqul/dracula.nvim",
  -- name = "dracula",
  -- "folke/tokyonight.nvim",
  -- name = 'tokyonight',
  "catppuccin/nvim",
  name = "catppuccin",
  lazy = false,    -- make sure we load this during startup if it is your main colorscheme
  priority = 1000, -- make sure to load this before all the other start plugins
}
-- dracula options
-- M.opts = {
--   -- customize dracula color palette
--   colors = {
--     bg = "#282A36",
--     fg = "#F8F8F2",
--     selection = "#44475A",
--     comment = "#6272A4",
--     red = "#FF5555",
--     orange = "#FFB86C",
--     yellow = "#F1FA8C",
--     green = "#50fa7b",
--     purple = "#BD93F9",
--     cyan = "#8BE9FD",
--     pink = "#FF79C6",
--     bright_red = "#FF6E6E",
--     bright_green = "#69FF94",
--     bright_yellow = "#FFFFA5",
--     bright_blue = "#D6ACFF",
--     bright_magenta = "#FF92DF",
--     bright_cyan = "#A4FFFF",
--     bright_white = "#FFFFFF",
--     menu = "#21222C",
--     visual = "#3E4452",
--     gutter_fg = "#4B5263",
--     nontext = "#3B4048",
--     white = "#ABB2BF",
--     black = "#191A21",
--   },
--   -- show the '~' characters after the end of buffers
--   show_end_of_buffer = true, -- default false
--   -- use transparent background
--   transparent_bg = true, -- default false
--   -- set custom lualine background color
--   lualine_bg_color = "#44475a", -- default nil
--   -- set italic comment
--   italic_comment = true, -- default false
--   -- overrides the default highlights with table see `:h synIDattr`
--   overrides = {},
--   -- You can use overrides as table like this
--   -- overrides = {
--   --   NonText = { fg = "white" }, -- set NonText fg to white
--   --   NvimTreeIndentMarker = { link = "NonText" }, -- link to NonText highlight
--   --   Nothing = {} -- clear highlight of Nothing
--   -- },
--   -- Or you can also use it like a function to get color from theme
--   -- overrides = function (colors)
--   --   return {
--   --     NonText = { fg = colors.white }, -- set NonText fg to white of theme
--   --   }
--   -- END,
-- }

-- tokyonight options
-- M.opts = {
--   -- Configure here or leave it
--   -- empty to use the default settings
--   style = "moon", -- The theme comes in three styles, `storm`, `moon`, a darker variant `night` and `day`
--   light_style = "day", -- The theme is used when the background is set to light
--   transparent = false, -- Enable this to disable setting the background color
--   terminal_colors = true, -- Configure the colors used when opening a `:terminal` in [Neovim](https://github.com/neovim/neovim)
--   styles = {
--     -- Style to be applied to different syntax groups
--     -- Value is any valid attr-list value for `:help nvim_set_hl`
--     comments = { italic = true },
--     keywords = { italic = true },
--     functions = {},
--     variables = {},
--     -- Background styles. Can be "dark", "transparent" or "normal"
--     sidebars = "dark", -- style for sidebars, see below
--     floats = "dark", -- style for floating windows
--   },
--   sidebars = { "qf", "help" }, -- Set a darker background on sidebar-like windows. For example: `["qf", "vista_kind", "terminal", "packer"]`
--   day_brightness = 0.3, -- Adjusts the brightness of the colors of the **Day** style. Number between 0 and 1, from dull to vibrant colors
--   hide_inactive_statusline = false, -- Enabling this option, will hide inactive statuslines and replace them with a thin border instead. Should work with the standard **StatusLine** and **LuaLine**.
--   dim_inactive = false, -- dims inactive windows
--   lualine_bold = false, -- When `true`, section headers in the lualine theme will be bold
--
--   --- You can override specific color groups to use other groups or a hex color
--   --- function will be called with a ColorScheme table
--   ---@param colors ColorScheme
--   on_colors = function(colors) end,
--
--   --- You can override specific highlights to use other groups or a hex color
--   --- function will be called with a Highlights and ColorScheme table
--   ---@param highlights Highlights
--   ---@param colors ColorScheme
--   on_highlights = function(highlights, colors)
--     local prompt = "#2d3149"
--
--     highlights.TelescopeNormal = {
--       bg = colors.bg_dark,
--       fg = colors.fg_dark,
--     }
--     highlights.TelescopeBorder = {
--       bg = colors.bg_dark,
--       fg = colors.fg_dark
--     }
--     highlights.TelescopePromptNormal = {
--       bg = prompt,
--     }
--     highlights.TelescopePromptBorder = {
--       bg = prompt,
--       fg = prompt,
--     }
--     highlights.TelescopePromptTitle = {
--       bg = prompt,
--       fg = prompt,
--     }
--     highlights.TelescopePreviewTitle = {
--       bg = colors.bg_dark,
--       fg = colors.fg_dark,
--     }
--     highlights.TelescopeResultsTitle = {
--       bg = colors.bg_dark,
--       fg = colors.fg_dark,
--     }
--   end,
-- }

-- catpuccin options
M.opts = {
  flavour = "macchiato", -- auto, latte, frappe, macchiato, mocha
  background = { -- :h background
    light = "latte",
    dark = "macchiato",
  },
  transparent_background = false, -- disables setting the background color.
  show_end_of_buffer = false, -- shows the '~' characters after the end of buffers
  term_colors = false, -- sets terminal colors (e.g. `g:terminal_color_0`)
  dim_inactive = {
    enabled = true, -- dims the background color of inactive window
    shade = "dark",
    percentage = 0.15, -- percentage of the shade to apply to the inactive window
  },
  no_italic = false, -- Force no italic
  no_bold = false, -- Force no bold
  no_underline = false, -- Force no underline
  styles = { -- Handles the styles of general hi groups (see `:h highlight-args`):
    comments = { "italic" }, -- Change the style of comments
    conditionals = { "italic" },
    loops = {},
    functions = {},
    keywords = {},
    strings = {},
    variables = {},
    numbers = {},
    booleans = {},
    properties = {},
    types = {},
    operators = {},
    -- miscs = {}, -- Uncomment to turn off hard-coded styles
  },
  color_overrides = {},
  custom_highlights = {},
  default_integrations = true,
  integrations = {
    alpha = true,
    cmp = true,
    dap_ui = true,
    gitsigns = true,
    harpoon = true,
    illuminate = true,
    indent_blankline = {
      enabled = true,
      scope_color = "", -- catppuccin color (eg. `lavender`) Default: text
      colored_indent_levels = false,
    },
    mason = true,
    native_lsp = {
      enabled = true,
      virtual_text = {
        errors = { "italic" },
        hints = { "italic" },
        warnings = { "italic" },
        information = { "italic" },
        ok = { "italic" },
      },
      underlines = {
        errors = { "underline" },
        hints = { "underling" },
        warnings = { "underling" },
        information = { "underling" },
        ok = { "underling" },
      },
      inlay_hints = {
        background = true,
      }
    },
    navic = {
      enabled = true,
      custom_bg = "NONE",
    },
    notify = true,
    nvim_surround = true,
    nvimtree = true,
    telescope = true,
    treesitter = true,
    which_key = true,
    -- For more plugins integrations visit https://github.com/catppuccin/nvim#integrations
  },
}

function M.config()
  local status_ok, _ = pcall(vim.cmd.colorscheme, M.name)
  if not status_ok then
    return
  end
end

return M
