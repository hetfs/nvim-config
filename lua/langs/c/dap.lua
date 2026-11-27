-- C language debugging configuration.
-- The shared DAP setup owns adapter registration.

local M = {}

function M.setup()
  local dap = require("dap")

  dap.configurations.c = {
    {
      name = "Launch C executable",
      type = "lldb",
      request = "launch",

      program = function()
        return vim.fn.input("Executable: ", vim.fn.getcwd() .. "/", "file")
      end,

      cwd = function()
        return vim.fn.getcwd()
      end,

      stopOnEntry = true,
      args = {},
      runInTerminal = false,
    },
  }
end

return M
