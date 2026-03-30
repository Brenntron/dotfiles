-- Git: gitsigns.nvim

require("gitsigns").setup({
  signs = {
    add = { text = "▎" },
    change = { text = "▎" },
    delete = { text = "" },
    topdelete = { text = "" },
    changedelete = { text = "▎" },
    untracked = { text = "▎" },
  },
  signs_staged = {
    add = { text = "▎" },
    change = { text = "▎" },
    delete = { text = "" },
    topdelete = { text = "" },
    changedelete = { text = "▎" },
  },
  on_attach = function(bufnr)
    local gs = require("gitsigns")
    local map = vim.keymap.set

    local function opts(desc)
      return { buffer = bufnr, desc = desc }
    end

    -- Navigation
    map("n", "]h", function() gs.nav_hunk("next") end, opts("Next Hunk"))
    map("n", "[h", function() gs.nav_hunk("prev") end, opts("Prev Hunk"))
    map("n", "]H", function() gs.nav_hunk("last") end, opts("Last Hunk"))
    map("n", "[H", function() gs.nav_hunk("first") end, opts("First Hunk"))

    -- Actions
    map({ "n", "v" }, "<leader>ghs", ":Gitsigns stage_hunk<cr>", opts("Stage Hunk"))
    map({ "n", "v" }, "<leader>ghr", ":Gitsigns reset_hunk<cr>", opts("Reset Hunk"))
    map("n", "<leader>ghS", gs.stage_buffer, opts("Stage Buffer"))
    map("n", "<leader>ghu", gs.undo_stage_hunk, opts("Undo Stage Hunk"))
    map("n", "<leader>ghR", gs.reset_buffer, opts("Reset Buffer"))
    map("n", "<leader>ghp", gs.preview_hunk_inline, opts("Preview Hunk Inline"))
    map("n", "<leader>ghd", gs.diffthis, opts("Diff This"))
    map("n", "<leader>ghD", function() gs.diffthis("~") end, opts("Diff This ~"))
    map("n", "<leader>ghb", function() gs.blame_line({ full = true }) end, opts("Blame Line"))
    map("n", "<leader>ghB", function() gs.blame() end, opts("Blame Buffer"))

    -- Text object
    map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<cr>", opts("Select Hunk"))
  end,
})
