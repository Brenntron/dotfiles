-- UI: snacks.nvim, bufferline, lualine, noice, mini.icons

-- Mini Icons (load first, other plugins may use it)
require("mini.icons").setup()
MiniIcons.mock_nvim_web_devicons()

-- Snacks
require("snacks").setup({
  animate = { enabled = true },
  bigfile = { enabled = true },
  bufdelete = { enabled = true },
  dashboard = {
    enabled = true,
    width = 60,
    pane_gap = 4,
    autokeys = "1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ",
    preset = {
      keys = {
        { icon = "󰈞 ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
        { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
        { icon = " ", key = "g", desc = "Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
        { icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
        {
          icon = " ",
          key = "c",
          desc = "Config",
          action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})",
        },
        { icon = " ", key = "s", desc = "Restore Session", section = "session" },
        { icon = "󰜺 ", key = "q", desc = "Quit", action = ":qa" },
      },
      header = [[
        ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
        ██████╗ ██████╗ ███████╗███╗   ██╗███╗   ██╗████████╗██████╗  ██████╗ ███╗   ██╗
        ██╔══██╗██╔══██╗██╔════╝████╗  ██║████╗  ██║╚══██╔══╝██╔══██╗██╔═══██╗████╗  ██║
        ██████╔╝██████╔╝█████╗  ██╔██╗ ██║██╔██╗ ██║   ██║   ██████╔╝██║   ██║██╔██╗ ██║
        ██╔══██╗██╔══██╗██╔══╝  ██║╚██╗██║██║╚██╗██║   ██║   ██╔══██╗██║   ██║██║╚██╗██║
        ██████╔╝██║  ██║███████╗██║ ╚████║██║ ╚████║   ██║   ██║  ██║╚██████╔╝██║ ╚████║
        ╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝  ╚═══╝╚═╝  ╚═══╝   ╚═╝   ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝
        ▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄ ]],
    },
    formats = {
      icon = function(item)
        if item.file and item.icon == "file" or item.icon == "directory" then
          return M.icon(item.file, item.icon)
        end
        return { item.icon, width = 2, hl = "icon" }
      end,
      footer = { "%s", align = "center" },
      header = { "%s", align = "center" },
      file = function(item, ctx)
        local fname = vim.fn.fnamemodify(item.file, ":~")
        fname = ctx.width and #fname > ctx.width and vim.fn.pathshorten(fname) or fname
        if #fname > ctx.width then
          local dir = vim.fn.fnamemodify(fname, ":h")
          local file = vim.fn.fnamemodify(fname, ":t")
          if dir and file then
            file = file:sub(-(ctx.width - #dir - 2))
            fname = dir .. "/…" .. file
          end
        end
        local dir, file = fname:match("^(.*)/(.+)$")
        return dir and { { dir .. "/", hl = "dir" }, { file, hl = "file" } } or { { fname, hl = "file" } }
      end,
    },
    sections = {
      { section = "header" },
      { section = "keys", gap = 1, padding = 1 },
      { section = "startup", enabled = package.loaded.lazy ~= nil },
    },
  },
  debug = { enabled = true },
  dim = { enabled = true },
  explorer = { enabled = true },
  git = { enabled = true },
  gitbrowse = { enabled = true },
  image = { enabled = true },
  indent = { enabled = true },
  input = { enabled = true },
  lazygit = { enabled = true },
  notifier = { enabled = true },
  notify = { enabled = true },
  picker = { enabled = true },
  profiler = { enabled = true },
  quickfile = { enabled = true },
  rename = { enabled = true },
  scope = { enabled = true },
  scratch = { enabled = true },
  terminal = { enabled = true },
  statuscolumn = { enabled = true },
})

-- Bufferline
require("bufferline").setup({
  options = {
    close_command = function(n) Snacks.bufdelete(n) end,
    right_mouse_command = function(n) Snacks.bufdelete(n) end,
    diagnostics = "nvim_lsp",
    always_show_bufferline = false,
    offsets = {
      {
        filetype = "snacks_layout_box",
        text = "File Explorer",
        highlight = "Directory",
        text_align = "left",
      },
    },
  },
  highlights = require("catppuccin.special.bufferline").get_theme(),
})

-- Lualine
require("lualine").setup({
  options = {
    theme = "catppuccin-macchiato",
    globalstatus = true,
    disabled_filetypes = { statusline = { "dashboard", "snacks_dashboard" } },
  },
  sections = {
    lualine_a = { "mode" },
    lualine_b = { "branch" },
    lualine_c = {
      { "diagnostics" },
      { "filetype", icon_only = true, separator = "", padding = { left = 1, right = 0 } },
      { "filename", path = 1 },
    },
    lualine_x = { "diff" },
    lualine_y = {
      { "progress", separator = " ", padding = { left = 1, right = 0 } },
      { "location", padding = { left = 0, right = 1 } },
    },
    lualine_z = { "encoding" },
  },
})

-- Noice
require("noice").setup({
  lsp = {
    override = {
      ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
      ["vim.lsp.util.stylize_markdown"] = true,
    },
  },
  routes = {
    {
      filter = {
        event = "msg_show",
        any = {
          { find = "%d+L, %d+B" },
          { find = "; after #%d+" },
          { find = "; before #%d+" },
        },
      },
      view = "mini",
    },
  },
  presets = {
    bottom_search = true,
    command_palette = true,
    long_message_to_split = true,
  },
})
