-- Restart and session resume helpers.
-- Functions only; keymaps live in config/keymaps.lua.
-- Requires Neovim >= 0.12.

local M = {}

local function notify(message, level)
  vim.notify(message, level or vim.log.levels.INFO, {
    title = "Restart",
  })
end

-- ============================================================
-- Restart
-- ============================================================

function M.restart()
  local ok, err = pcall(vim.cmd, "restart")

  if not ok then
    notify("Restart failed: " .. tostring(err), vim.log.levels.ERROR)
  end
end

-- ============================================================
-- Resume Session
-- ============================================================

function M.resume()
  local ok, sessions = pcall(require, "mini.sessions")

  if not ok then
    notify("mini.sessions is not available", vim.log.levels.ERROR)
    return
  end

  local read_ok, result = pcall(sessions.read)

  if not read_ok then
    notify("Session restore failed: " .. tostring(result), vim.log.levels.ERROR)
    return
  end

  if result == false then
    notify("No session could be restored", vim.log.levels.WARN)
  end
end

-- ============================================================
-- Rerun Last Ex Command
-- ============================================================

function M.rerun_last_command()
  local command = vim.fn.histget(":", -1)

  if command == "" then
    notify("No previous Ex command found", vim.log.levels.WARN)
    return
  end

  vim.ui.select({ "Run", "Cancel" }, {
    prompt = "Run :" .. command .. "?",
  }, function(choice)
    if choice ~= "Run" then
      return
    end

    local ok, err = pcall(vim.cmd, command)

    if not ok then
      notify("Command failed: " .. tostring(err), vim.log.levels.ERROR)
    end
  end)
end

return M
