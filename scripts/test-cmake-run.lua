
local cmake = require("config.cmake")

local temp = vim.fn.tempname()
local root = vim.fs.joinpath(temp, "project")
local build_dir = vim.fs.joinpath(root, "build")
local source = vim.fs.joinpath(root, "main.cpp")
local executable = vim.fs.joinpath(build_dir, "app.exe")

local original_notify = vim.notify
local original_input = vim.ui.input
local original_executable = vim.fn.executable
local original_jobstart = vim.fn.jobstart
local original_cwd = vim.fn.getcwd()
local original_win = vim.api.nvim_get_current_win()

local buf
local notifications = {}
local job_calls = {}
local terminal_win
local terminal_buf

local function write(path, content)
  vim.fn.mkdir(vim.fs.dirname(path), "p")
  assert(vim.fn.writefile({ content or "" }, path) == 0)
end

local function equal(actual, expected, label)
  assert(
    actual == expected,
    string.format(
      "%s: expected %s, got %s",
      label,
      vim.inspect(expected),
      vim.inspect(actual)
    )
  )
end

local function window_count()
  return #vim.api.nvim_list_wins()
end

local function cleanup_terminal()
  if terminal_win and vim.api.nvim_win_is_valid(terminal_win) then
    vim.api.nvim_win_close(terminal_win, true)
  end

  if terminal_buf and vim.api.nvim_buf_is_valid(terminal_buf) then
    vim.api.nvim_buf_delete(terminal_buf, { force = true })
  end

  terminal_win = nil
  terminal_buf = nil
end

local function cleanup()
  pcall(vim.cmd, "stopinsert")

  cleanup_terminal()

  vim.notify = original_notify
  vim.ui.input = original_input
  vim.fn.executable = original_executable
  vim.fn.jobstart = original_jobstart

  if original_win and vim.api.nvim_win_is_valid(original_win) then
    vim.api.nvim_set_current_win(original_win)
  end

  vim.api.nvim_set_current_dir(original_cwd)

  if buf and vim.api.nvim_buf_is_valid(buf) then
    vim.api.nvim_buf_delete(buf, { force = true })
  end

  vim.fn.delete(temp, "rf")
end

local function stub_input(input)
  vim.ui.input = function(_, callback)
    callback(input)
  end
end

local function stub_executable(expected_path)
  vim.fn.executable = function(path)
    if vim.fs.normalize(path) == vim.fs.normalize(expected_path) then
      return 1
    end

    return original_executable(path)
  end
end

local function stub_jobstart(result)
  job_calls = {}
  terminal_win = nil
  terminal_buf = nil

  vim.fn.jobstart = function(command, options)
    terminal_win = vim.api.nvim_get_current_win()
    terminal_buf = vim.api.nvim_get_current_buf()

    job_calls[#job_calls + 1] = {
      command = vim.deepcopy(command),
      options = vim.deepcopy(options),
    }

    return result
  end
end

local function invoke_run(input, job_result)
  notifications = {}

  stub_input(input)
  stub_executable(executable)
  stub_jobstart(job_result)

  cmake.run(buf)
end

local ok, err = xpcall(function()
  -- Prepare a minimal CMake project and executable fixture.
  write(vim.fs.joinpath(root, "CMakeLists.txt"))
  write(source, "int main() { return 0; }")
  write(executable, "test executable fixture")

  buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_name(buf, source)

  vim.notify = function(message, level)
    notifications[#notifications + 1] = {
      message = message,
      level = level,
    }
  end

  -- Run Neovim from outside the project directory.
  vim.api.nvim_set_current_dir(temp)

  -- Cancelled input must not start a process or show a notification.
  local initial_windows = window_count()

  invoke_run(nil, 42)

  equal(#job_calls, 0, "Cancelled input process count")
  equal(#notifications, 0, "Cancelled input notification count")
  equal(window_count(), initial_windows, "Cancelled input window count")

  print("PASS cancelled executable input")

  -- Empty input must also be ignored.
  invoke_run("", 42)

  equal(#job_calls, 0, "Empty input process count")
  equal(#notifications, 0, "Empty input notification count")
  equal(window_count(), initial_windows, "Empty input window count")

  print("PASS empty executable input")

  -- A directory must not be accepted as an executable.
  invoke_run("build", 42)

  equal(#job_calls, 0, "Directory process count")
  equal(#notifications, 1, "Directory notification count")

  assert(
    notifications[1].message:match("Not an executable file"),
    "Directory input was not rejected"
  )

  equal(
    window_count(),
    initial_windows,
    "Directory input window count"
  )

  print("PASS directory executable rejection")

  -- A missing executable must be rejected.
  invoke_run("build/missing.exe", 42)

  equal(#job_calls, 0, "Missing executable process count")
  equal(#notifications, 1, "Missing executable notification count")

  assert(
    notifications[1].message:match("Not an executable file"),
    "Missing executable was not rejected"
  )

  equal(
    window_count(),
    initial_windows,
    "Missing executable window count"
  )

  print("PASS missing executable rejection")

  -- A relative executable path must resolve against the project root.
  invoke_run("build/app.exe", 42)

  equal(#notifications, 0, "Successful run notification count")
  equal(#job_calls, 1, "Successful run process count")

  equal(
    #job_calls[1].command,
    1,
    "Executable argument count"
  )

  equal(
    job_calls[1].command[1],
    executable,
    "Resolved executable path"
  )

  equal(
    job_calls[1].options.cwd,
    root,
    "Executable working directory"
  )

  equal(
    job_calls[1].options.term,
    true,
    "Terminal execution option"
  )

  equal(
    vim.api.nvim_get_current_win(),
    terminal_win,
    "Terminal window selection"
  )

  print("PASS relative executable path and terminal options")

  -- Clean up the successful test terminal before testing failures.
  cleanup_terminal()

  -- A zero job ID must trigger terminal cleanup.
  local windows_before_failure = window_count()

  invoke_run("build/app.exe", 0)

  equal(#job_calls, 1, "Failed job process count")
  equal(#notifications, 1, "Failed job notification count")

  assert(
    notifications[1].message:match("^Failed to start:"),
    "Failed job notification was not reported"
  )

  equal(
    notifications[1].level,
    vim.log.levels.ERROR,
    "Failed job notification level"
  )

  equal(
    window_count(),
    windows_before_failure,
    "Failed job window cleanup"
  )

  assert(
    terminal_win and not vim.api.nvim_win_is_valid(terminal_win),
    "Failed job terminal window was not closed"
  )

  assert(
    terminal_buf and not vim.api.nvim_buf_is_valid(terminal_buf),
    "Failed job terminal buffer was not deleted"
  )

  print("PASS zero job ID cleanup")

  -- A negative job ID must also trigger terminal cleanup.
  local windows_before_negative = window_count()

  invoke_run("build/app.exe", -1)

  equal(#job_calls, 1, "Negative job process count")
  equal(#notifications, 1, "Negative job notification count")

  assert(
    notifications[1].message:match("^Failed to start:"),
    "Negative job notification was not reported"
  )

  equal(
    window_count(),
    windows_before_negative,
    "Negative job window cleanup"
  )

  assert(
    terminal_win and not vim.api.nvim_win_is_valid(terminal_win),
    "Negative job terminal window was not closed"
  )

  assert(
    terminal_buf and not vim.api.nvim_buf_is_valid(terminal_buf),
    "Negative job terminal buffer was not deleted"
  )

  print("PASS negative job ID cleanup")
end, debug.traceback)

cleanup()

if not ok then
  error(err)
end
