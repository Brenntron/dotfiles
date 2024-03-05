local M = {
  "goolord/alpha-nvim",
  event = "VimEnter",
  dependencies = {
    {
      "nvim-tree/nvim-web-devicons",
    }
  }
}

function M.config()
  local alpha = require "alpha"
  local dashboard = require "alpha.themes.dashboard"
  local icons = require "utils.icons"

  local function button(sc, txt, keybind, keybind_opts)
    local b = dashboard.button(sc, txt, keybind, keybind_opts)
    b.opts.hl_shortcut = "Macro"
    return b
  end

  dashboard.section.header.val = {
    [[      ::::::::: ::::::::: ::::::::::::::    :::::::    :::::::::::::::::::::::  :::::::: ::::    :::]],
    [[     :+:    :+::+:    :+::+:       :+:+:   :+::+:+:   :+:    :+:    :+:    :+::+:    :+::+:+:   :+: ]],
    [[    +:+    +:++:+    +:++:+       :+:+:+  +:+:+:+:+  +:+    +:+    +:+    +:++:+    +:+:+:+:+  +:+  ]],
    [[   +#++:++#+ +#++:++#: +#++:++#  +#+ +:+ +#++#+ +:+ +#+    +#+    +#++:++#: +#+    +:++#+ +:+ +#+   ]],
    [[  +#+    +#++#+    +#++#+       +#+  +#+#+#+#+  +#+#+#    +#+    +#+    +#++#+    +#++#+  +#+#+#    ]],
    [[ #+#    #+##+#    #+##+#       #+#   #+#+##+#   #+#+#    #+#    #+#    #+##+#    #+##+#   #+#+#     ]],
    [[######### ###    ################    #######    ####    ###    ###    ### ######## ###    ####      ]],
  }

  dashboard.section.buttons.val = {
    button("f", icons.ui.Files .. " Find file", ":Telescope find_files <CR>"),
    button("e", icons.ui.NewFile .. " New file", ":ene <BAR> startinsert <CR>"),
    button("p", icons.git.Repo .. " Find project", ":lua require('telescope').extensions.projects.projects()<CR>"),
    button("r", icons.ui.History .. " Recent files", ":Telescope oldfiles <CR>"),
    button("t", icons.ui.Text .. " Find text", ":Telescope live_grep <CR>"),
    button("c", icons.ui.Gear .. " Config", ":e $MYVIMRC <CR>"),
    button("q", icons.ui.SignOut .. " Quit", ":qa<CR>"),
  }

  dashboard.section.footer.val = "brenntron.dev"
  dashboard.section.header.opts.hl = "Include"
  dashboard.section.footer.opts.hl = "Type"
  dashboard.section.buttons.opts.hl = "Keyword"

  dashboard.opts.opts.noautocmd = true
  alpha.setup(dashboard.config)

  vim.api.nvim_create_autocmd("User", {
    pattern = "LazyVimStarted",
    callback = function()
      local stats = require("lazy").stats()
      local ms = (math.floor(stats.startuptime * 100 + 0.5) / 100)

      dashboard.section.footer.val = "loaded " .. stats.count .. " plugins in " .. ms .. "ms"
      pcall(vim.cmd.AlphaRedraw)
    end,
  })

  vim.api.nvim_create_autocmd({ "User" }, {
    pattern = { "AlphaReady" },
    callback = function()
      vim.cmd [[
      set laststatus=0 | autocmd BufUnload <buffer> set laststatus=3
      ]]
    end,
  })
end

return M
