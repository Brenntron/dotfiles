local M = {
  "epwalsh/pomo.nvim",
  cmd = { "TimerStart", "TimerRepeat" },
  dependencies = {
    -- Optional, but highly recommended if you want to use the "Default" timer
    "rcarriga/nvim-notify",
  },
  lazy = true,
  opts = {
    work_interval = 25,
    short_break = 5,
    long_break = 15,
    cycles = 4,
    default_timer = "work",
    auto_start = false,
    on_complete = function(timer)
      require "notify"("Pomo", "Timer completed: " .. timer)
    end,
  },
}

return M
