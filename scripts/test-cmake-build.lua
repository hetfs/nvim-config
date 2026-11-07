local cmake = require("config.cmake")

local temp = vim.fn.tempname()
local root = vim.fs.joinpath(temp, "project")
local nested = vim.fs.joinpath(root, "src", "nested")
local build_dir = vim.fs.joinpath(root, "build")
local source = vim.fs.joinpath(nested, "main.cpp")

local buf
local original_notify = vim.notify
local original_cwd = vim.fn.getcwd()

local notifications = {}

local function write(path, content)
  vim.fn.mkdir(vim.fs.dirname(path), "p")
  assert(vim.fn.writefile({ content or "" }, path) == 0)
end

local function equal(actual, expected, label)
  assert(actual == expected, string.format("%s: expected %s, got %s", label, vim.inspect(expected), vim.inspect(actual)))
end

local function cleanup()
  vim.notify = original_notify
  vim.api.nvim_set_current_dir(original_cwd)

  if buf and vim.api.nvim_buf_is_valid(buf) then
    vim.api.nvim_buf_delete(buf, { force = true })
  end

  vim.fn.delete(temp, "rf")
end

local ok, err = xpcall(function()
  -- Create a project with nested CMakeLists.txt files.
  write(vim.fs.joinpath(root, "CMakeLists.txt"))
  write(vim.fs.joinpath(root, "src", "CMakeLists.txt"))
  write(vim.fs.joinpath(nested, "CMakeLists.txt"))
  write(source, "int main() { return 0; }")

  buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_name(buf, source)

  vim.notify = function(message, level)
    notifications[#notifications + 1] = {
      message = message,
      level = level,
    }
  end

  -- Verify argument-list command construction.
  local command = cmake.build_command(build_dir)

  equal(command[1], "cmake", "Build executable")
  equal(command[2], "--build", "Build argument")
  equal(command[3], build_dir, "Build directory argument")
  equal(#command, 3, "Build argument count")

  print("PASS CMake build command construction")

  -- Project root must not depend on Neovim's current directory.
  vim.api.nvim_set_current_dir(temp)

  local detected_root, root_error = cmake.root(buf)

  equal(root_error, nil, "Project root error")
  equal(detected_root, root, "Outermost CMake project root")

  print("PASS project root independent of current working directory")

  -- Missing build directory must produce a configure hint.
  notifications = {}

  cmake.build(buf)

  equal(#notifications, 1, "Missing build notification count")

  assert(notifications[1].message:match("No build/ directory"), "Missing-build notification did not identify the missing build directory")

  assert(notifications[1].message:match("cmake %-S %. %-B build"), "Missing-build notification did not include the configure command")

  equal(notifications[1].level, vim.log.levels.WARN, "Missing-build notification level")

  print("PASS missing build directory validation")
end, debug.traceback)

cleanup()

if not ok then
  error(err)
end
