local M = {
  "mfussenegger/nvim-dap",
  event = "VeryLazy",
  dependencies = {
    {
      "liadOz/nvim-dap-repl-highlights",
      event = "VeryLazy",
    }
  },
  config = function()
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

    -- Javascript setup
    dap.adapters.chrome = {
      type = "executable",
      command = "node",
      args = { os.getenv("HOME") .. "/.config/nvim/dap_install/jsnode_modules/vscode-chrome-debug/out/src/chromeDebug.js" },
    }

    dap.adapters.firefox = {
      type = "executable",
      command = "node",
      args = { os.getenv("HOME") .. "/.config/nvim/dap_install/jsnode_modules/vscode-firefox-debug/out/src/firefoxDebug.js" },
    }

    dap.configurations.javascript = {
      {
        cwd = vim.fn.getcwd(),
        name = "Debug with Chrome",
        port = 9222,
        program = "${file}",
        protocol = "inspector",
        request = "attach",
        sourceMaps = true,
        type = "chrome",
        webRoot = "${workspaceFolder}",
      },
      {
        name = 'Debug with Firefox',
        type = 'firefox',
        request = "launch",
        reAttach = true,
        url = 'http://localhost:3000',
        webRoot = '${workspaceFolder}',
        firefoxExecutable = '/usr/bin/firefox',
      }
    }

    -- Ruby setup
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
}

return M
