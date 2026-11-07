local M = {}

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.WARN)
end

local function is_absolute(path)
  return path:match("^/") ~= nil or path:match("^%a:/") ~= nil or path:match("^\\\\") ~= nil
end

local function split_lines(output)
  local lines = vim.split(output or "", "\n", {
    plain = true,
    trimempty = true,
  })

  for i, line in ipairs(lines) do
    lines[i] = line:gsub("\r$", "")
  end

  return lines
end

--- Find the outermost CMakeLists.txt directory above the buffer.
--- Returns the project root, or nil and an error message.
function M.root(buf)
  buf = buf or vim.api.nvim_get_current_buf()

  if not vim.api.nvim_buf_is_valid(buf) then
    return nil, "Invalid buffer"
  end

  local name = vim.api.nvim_buf_get_name(buf)
  if name == "" or vim.bo[buf].buftype ~= "" then
    return nil, "Buffer has no file path; save it first"
  end

  local dir = vim.fs.dirname(vim.fs.normalize(name))
  local found = vim.fs.find("CMakeLists.txt", {
    upward = true,
    path = dir,
    limit = math.huge,
  })

  local top = found[#found]
  if not top then
    return nil, "No CMake project found above " .. dir
  end

  return vim.fs.dirname(top)
end

--- Build the CMake command as an argument list.
--- Keeping arguments separate avoids shell quoting issues.
function M.build_command(build_dir)
  return {
    "cmake",
    "--build",
    build_dir,
  }
end

--- Convert build output into quickfix entries.
--- CMake and compiler diagnostics commonly use file:line:column formats.
function M.quickfix_items(output)
  local items = {}

  for _, line in ipairs(split_lines(output)) do
    local filename, lnum, col, message = line:match("^(.+):(%d+):(%d+):%s*(.*)$")

    if not filename then
      filename, lnum, message = line:match("^(.+):(%d+):%s*(.*)$")
      col = nil
    end

    if filename and lnum then
      items[#items + 1] = {
        filename = filename,
        lnum = tonumber(lnum),
        col = tonumber(col) or 1,
        text = message,
        type = message:match("^fatal error") and "E" or message:match("^error") and "E" or message:match("^warning") and "W" or nil,
      }
    end
  end

  return items
end

local function show_build_output(result, root)
  local output = (result.stdout or "") .. (result.stderr or "")
  local items = M.quickfix_items(output)

  vim.fn.setqflist({}, " ", {
    title = "CMake build: " .. root,
    items = items,
  })

  if #items > 0 then
    vim.cmd("copen")
  else
    vim.cmd("cclose")
  end
end

function M.build(buf)
  buf = buf or vim.api.nvim_get_current_buf()

  local root, err = M.root(buf)
  if not root then
    return notify(err)
  end

  local build_dir = vim.fs.normalize(vim.fs.joinpath(root, "build"))

  if vim.fn.isdirectory(build_dir) == 0 then
    return notify("No build/ directory in " .. root .. ". Configure first: cmake -S . -B build")
  end

  local command = M.build_command(build_dir)

  local ok, result = pcall(function()
    return vim
      .system(command, {
        cwd = root,
        text = true,
      })
      :wait()
  end)

  if not ok then
    return notify("Could not execute CMake build: " .. tostring(result), vim.log.levels.ERROR)
  end

  show_build_output(result, root)

  if result.code ~= 0 then
    local detail = result.signal ~= 0 and (" (signal " .. result.signal .. ")") or ""

    return notify("Build failed" .. detail .. " (exit code " .. result.code .. ")", vim.log.levels.ERROR)
  end

  notify("Build succeeded", vim.log.levels.INFO)
end

function M.run(buf)
  buf = buf or vim.api.nvim_get_current_buf()

  local root, err = M.root(buf)
  if not root then
    return notify(err)
  end

  vim.ui.input({
    prompt = "Executable: ",
    default = "",
    completion = "file",
  }, function(input)
    if not input or input == "" then
      return
    end

    local path = vim.fs.normalize(input)

    if not is_absolute(path) then
      path = vim.fs.normalize(vim.fs.joinpath(root, path))
    end

    if vim.fn.isdirectory(path) == 1 or vim.fn.executable(path) ~= 1 then
      return notify("Not an executable file: " .. path)
    end

    vim.cmd("botright new")

    local win = vim.api.nvim_get_current_win()
    local term_buf = vim.api.nvim_get_current_buf()

    local job = vim.fn.jobstart({ path }, {
      term = true,
      cwd = root,
    })

    if job <= 0 then
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end

      if vim.api.nvim_buf_is_valid(term_buf) then
        vim.api.nvim_buf_delete(term_buf, { force = true })
      end

      return notify("Failed to start: " .. path, vim.log.levels.ERROR)
    end

    vim.cmd("startinsert")
  end)
end

function M.setup()
  vim.api.nvim_create_user_command("CMakeBuild", function()
    M.build()
  end, {
    desc = "Build the current CMake project",
  })

  vim.api.nvim_create_user_command("CMakeRun", function()
    M.run()
  end, {
    desc = "Run an executable from the current CMake project",
  })
end

return M
