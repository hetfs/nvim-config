-- DAP adapter registration.
-- Debugger executables are managed outside Neovim.

local M = {}

function M.setup()
  local dap = require("dap")
  local adapters = require("config.dap.adapters")

  dap.adapters.lldb = adapters.lldb
end

return M
