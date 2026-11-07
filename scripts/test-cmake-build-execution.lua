local cmake = require("config.cmake")

local temp = vim.fn.tempname()
local root = vim.fs.joinpath(temp, "project")
local build_dir = vim.fs.joinpath(root, "build")
local source = vim.fs.joinpath(root, "main.cpp")

local buf
local original_notify = vim.notify
local original_system = vim.system
local original_cwd = vim.fn.getcwd()

local notifications = {}
local system_calls = {}

local function write(path, content)
  vim.fn.mkdir(vim.fs.dirname(path), "p")
  assert(vim.fn.writefile({ content or "" }, path) == 0)
end

local function equal(actual, expected, label)
  assert(actual == expected, string.format("%s: expected %s, got %s", label, vim.inspect(expected), vim.inspect(actual)))
end

local function cleanup()
  vim.notify = original_notify
  vim.system = original_system
  vim.api.nvim_set_current_dir(original_cwd)

  if buf and vim.api.nvim_buf_is_valid(buf) then
    vim.api.nvim_buf_delete(buf, { force = true })
  end

  vim.fn.delete(temp, "rf")
end

local function stub_system(result)
  system_calls = {}

  vim.system = function(command, options)
    system_calls[#system_calls + 1] = {
      command = vim.deepcopy(command),
      options = vim.deepcopy(options),
    }

    return {
      wait = function()
        return result
      end,
    }
  end
end

local function run_build(result)
  notifications = {}
  stub_system(result)

  cmake.build(buf)

  equal(#notifications, 1, "Build notification count")
  equal(#system_calls, 1, "Process invocation count")

  return notifications[1], system_calls[1]
end

local ok, err = xpcall(function()
  -- Prepare a minimal CMake project.
  write(vim.fs.joinpath(root, "CMakeLists.txt"))
  write(source, "int main() { return 0; }")
  vim.fn.mkdir(build_dir, "p")

  buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_name(buf, source)

  vim.notify = function(message, level)
    notifications[#notifications + 1] = {
      message = message,
      level = level,
    }
  end

  -- Build command must use an argument list.
  local command = cmake.build_command(build_dir)

  equal(command[1], "cmake", "Build executable")
  equal(command[2], "--build", "Build argument")
  equal(command[3], build_dir, "Build directory argument")
  equal(#command, 3, "Build argument count")

  print("PASS CMake build command construction")

  -- Run Neovim from outside the project directory.
  vim.api.nvim_set_current_dir(temp)

  -- A nonzero exit code must report a build failure.
  local failure, failure_call = run_build({
    code = 1,
    signal = 0,
    stdout = "",
    stderr = "CMake build failed",
  })

  assert(failure.message:match("^Build failed"), "Failure notification did not report a build failure: " .. failure.message)

  assert(failure.message:match("exit code 1"), "Failure notification did not include the process exit code: " .. failure.message)

  equal(failure.level, vim.log.levels.ERROR, "Failure notification level")

  print("PASS failed process reports an error")

  -- Verify process arguments and working directory.
  equal(vim.inspect(failure_call.command), vim.inspect({ "cmake", "--build", build_dir }), "Failure command arguments")

  equal(failure_call.options.cwd, root, "Failure process working directory")

  equal(failure_call.options.text, true, "Failure text output option")

  print("PASS build uses project root as process working directory")

  -- A zero exit code must report success.
  local success, success_call = run_build({
    code = 0,
    signal = 0,
    stdout = "Build completed",
    stderr = "",
  })

  equal(success.message, "Build succeeded", "Success notification")
  equal(success.level, vim.log.levels.INFO, "Success notification level")

  equal(vim.inspect(success_call.command), vim.inspect({ "cmake", "--build", build_dir }), "Success command arguments")

  equal(success_call.options.cwd, root, "Success process working directory")

  equal(success_call.options.text, true, "Success text output option")

  print("PASS successful process reports success")

  -- A process-launch exception must be reported.
  notifications = {}

  vim.system = function()
    error("simulated process launch failure")
  end

  cmake.build(buf)

  equal(#notifications, 1, "Process launch failure notification count")

  assert(notifications[1].message:match("Could not execute CMake build"), "Process launch failure was not reported: " .. notifications[1].message)

  equal(notifications[1].level, vim.log.levels.ERROR, "Process launch failure notification level")

  print("PASS process launch errors are reported")

  -- Compiler output should be parsed into quickfix diagnostics.
  local quickfix = cmake.quickfix_items("src/main.cpp:12:5: error: expected expression\n" .. "src/main.cpp:18: warning: unused variable")

  equal(#quickfix, 2, "Quickfix diagnostic count")
  equal(quickfix[1].filename, "src/main.cpp", "Quickfix error filename")
  equal(quickfix[1].lnum, 12, "Quickfix error line")
  equal(quickfix[1].col, 5, "Quickfix error column")
  equal(quickfix[1].type, "E", "Quickfix error type")
  equal(quickfix[2].lnum, 18, "Quickfix warning line")
  equal(quickfix[2].type, "W", "Quickfix warning type")

  print("PASS compiler output parsing")
end, debug.traceback)

cleanup()

if not ok then
  error(err)
end
