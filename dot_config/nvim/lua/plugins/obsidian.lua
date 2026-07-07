require("obsidian").setup({
  legacy_commands = false, -- this will be removed in the next major release
  workspaces = {
    {
      name = "Second Brain",
      path = "~/Documents/'Second Brain'",
    },
    {
      name = "Work Notes",
      path = "~/Documents/Notes",
    },
  },
})
