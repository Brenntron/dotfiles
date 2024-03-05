local M = {
  "mfussenegger/nvim-dap",
  event = "VeryLazy",
}

function M.config()
  local dap = require "dap"

  local dap_ui_status_ok, dapui = pcall(require, "dapui")
  if not dap_ui_status_ok then
    return
  end

  dap.listeners.after.event_initialized["dapui_config"] = function()
    dapui.open()
  end

  dap.listeners.before.event_terminated["dapui_config"] = function()
    dapui.close()
  end

  dap.listeners.before.event_exited["dapui_config"] = function()
    dapui.close()
  end

  dap.adapters.ruby = function(callback, config)
    callback {
      type = "server",
      host = "127.0.0.1",
      port = "${port}",
      executable = {
        command = "bundle",
        args = { "exec", "rdbg", "-n", "--open", "--port", "${port}", "-c", "--", "bundle", "exec", config.command, config.script, },
      },
    }
  end

  dap.configurations.ruby = {
    {
      type = "ruby",
      name = "debug current file",
      request = "attach",
      localfs = true,
      command = "ruby",
      script = "${file}",
    },
    {
      type = "ruby",
      name = "run current spec file",
      request = "attach",
      localfs = true,
      command = "rspec",
      script = "${file}",
    },
    {
      type = "ruby",
      name = "run current cucumber file",
      request = "attach",
      localfs = true,
      command = "cucumber",
      script = "${file}",
    }
  }
end

return M
