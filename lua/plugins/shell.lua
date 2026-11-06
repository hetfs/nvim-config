-- Stage 13: Shell integration.
-- Bash execution and Bash Language Server support.
-- Language metadata comes from the enabled language-pack registry.

local M = {}

local SHELLCHECK_WIKI = "https://www.shellcheck.net/wiki/"

local function run_script(buf)
  -- Verify Bash availability.
  if vim.fn.executable("bash") == 0 then
    vim.notify_once("shell pack: bash not found, cannot run shell scripts", vim.log.levels.WARN)
    return
  end

  -- Verify that the target buffer is valid.
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  -- Get the target buffer's filename.
  local path = vim.api.nvim_buf_get_name(buf)

  if path == "" then
    vim.notify("Save the shell script before running it", vim.log.levels.WARN)
    return
  end

  -- Save the target buffer before execution.
  local ok, err = pcall(function()
    vim.api.nvim_buf_call(buf, function()
      vim.cmd.write()
    end)
  end)

  if not ok then
    vim.notify("shell pack: failed to save script: " .. tostring(err), vim.log.levels.ERROR)
    return
  end

  -- Create a dedicated terminal buffer.
  local term_buf = vim.api.nvim_create_buf(false, true)

  -- Open a terminal window.
  vim.cmd("botright 12split")

  local term_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(term_win, term_buf)

  -- Execute Bash directly using an argument list.
  local job_id = vim.fn.jobstart({
    "bash",
    path,
  }, {
    term = true,

    on_exit = function(_, exit_code)
      if exit_code ~= 0 then
        vim.schedule(function()
          vim.notify("shell pack: script exited with code " .. exit_code, vim.log.levels.WARN)
        end)
      end
    end,
  })

  -- Handle process startup failure.
  if job_id <= 0 then
    if vim.api.nvim_win_is_valid(term_win) then
      vim.api.nvim_win_close(term_win, true)
    end

    if vim.api.nvim_buf_is_valid(term_buf) then
      vim.api.nvim_buf_delete(term_buf, { force = true })
    end

    vim.notify("shell pack: failed to start Bash process", vim.log.levels.ERROR)
    return
  end
end

--- Find a ShellCheck rule diagnostic on the cursor line.
local function get_shellcheck_diagnostic(buf)
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1] - 1
  local col = cursor[2]
  local diagnostics = vim.diagnostic.get(buf)
  local matches = {}

  for _, diagnostic in ipairs(diagnostics) do
    local code = diagnostic.code

    if type(code) == "number" then
      code = tostring(code)
    end

    if type(code) == "string" and code:match("^SC%d%d%d%d$") and diagnostic.lnum == row then
      matches[#matches + 1] = {
        code = code,
        col = diagnostic.col or 0,
        distance = math.abs((diagnostic.col or 0) - col),
      }
    end
  end

  table.sort(matches, function(a, b)
    return a.distance < b.distance
  end)

  return matches[1] and matches[1].code or nil
end

--- Open the ShellCheck wiki page for the rule under the cursor.
local function shellcheck_wiki()
  local buf = vim.api.nvim_get_current_buf()
  local code = get_shellcheck_diagnostic(buf)

  if not code then
    vim.notify("ShellCheck: no rule diagnostic found on the current line", vim.log.levels.WARN)
    return
  end

  local url = SHELLCHECK_WIKI .. code
  local ok, err = pcall(vim.ui.open, url)

  if not ok then
    vim.notify("ShellCheck: failed to open wiki page: " .. tostring(err), vim.log.levels.ERROR)
  end
end

function M.setup()
  -- Respect language-pack activation.
  local langs = require("langs")

  if not langs.is_enabled("shell") then
    return
  end

  -- Obtain Shell metadata from the registry.
  local pack = require("langs.shell")

  -- Validate the metadata required by this integration.
  assert(type(pack.filetypes) == "table", "Shell pack must define filetypes")
  assert(type(pack.lsp) == "table", "Shell pack must define lsp metadata")

  -- Enable Bash Language Server when available.
  if vim.fn.executable("bash-language-server") == 0 then
    vim.notify_once("shell pack: bash-language-server not found", vim.log.levels.WARN)
  else
    for name, cfg in pairs(pack.lsp) do
      vim.lsp.config(name, cfg)
      vim.lsp.enable(name)
    end
  end

  -- ShellCheck provides lint diagnostics through bashls.
  if vim.fn.executable("shellcheck") == 0 then
    vim.notify_once("shell pack: shellcheck not found, no lint diagnostics", vim.log.levels.WARN)
  end

  -- Register the ShellCheck wiki command.
  vim.api.nvim_create_user_command("ShellcheckWiki", shellcheck_wiki, {
    desc = "Open ShellCheck wiki for diagnostic under cursor",
    force = true,
  })

  -- Register shell-specific workflows.
  local group = vim.api.nvim_create_augroup("config_shell", { clear = true })

  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = pack.filetypes,
    desc = "Register Shell workflows",

    callback = function(ev)
      vim.keymap.set("n", "<leader>cr", function()
        run_script(ev.buf)
      end, {
        buffer = ev.buf,
        desc = "Run shell script",
      })
    end,
  })
end

return M
