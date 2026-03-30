-- Edgy: window layout management for sidebars and panels

require("edgy").setup({
  bottom = {
    -- Trouble
    "Trouble",
    -- Quickfix
    { ft = "qf", title = "Quickfix" },
    {
      ft = "help",
      size = { heigh = 20 },
      -- don't open help files in edgy that we're editing
      filter = function(buf)
        return vim.bo[buf].buftype == "help"
      end,
    },
    -- Noice
    {
      ft = "noice",
      size = { height = 0.4 },
      filter = function(_, win)
        return vim.api.nvim_win_get_config(win).relative == ""
      end,
    },
  },
  keys = {
    -- increase width
    ["<c-Right>"] = function(win)
      win:resize("width", 2)
    end,
    -- decrease width
    ["<c-Left>"] = function(win)
      win:resize("width", -2)
    end,
    -- increase height
    ["<c-Up>"] = function(win)
      win:resize("height", 2)
    end,
    -- decrease height
    ["<c-Down>"] = function(win)
      win:resize("height", -2)
    end,
  },
  -- Don't open edgy when there's only one window with a filetype that's in the config
  exit_when_last = true,
  animate = { enabled = false },
})
