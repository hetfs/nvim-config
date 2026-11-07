local cmake = require("config.cmake")

local temp = vim.fn.tempname()
local root = vim.fs.joinpath(temp, "project")
local nested = vim.fs.joinpath(root, "subproject")
local source = vim.fs.joinpath(nested, "src", "main.cpp")
local no_project = vim.fs.joinpath(temp, "no-project", "main.cpp")

local buffers = {}

local function write(path, content)
  vim.fn.mkdir(vim.fs.dirname(path), "p")
  assert(vim.fn.writefile({ content or "" }, path) == 0, "Could not write " .. path)
end

local function buffer_for(path)
  local buf = vim.api.nvim_create_buf(true, false)
  buffers[#buffers + 1] = buf
  if path then
    vim.api.nvim_buf_set_name(buf, path)
  end
  return buf
end

local function equal(actual, expected, label)
  assert(actual == expected, string.format("%s: expected %s, got %s", label, vim.inspect(expected), vim.inspect(actual)))
end

local function cleanup()
  for _, buf in ipairs(buffers) do
    if vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end

  vim.fn.delete(temp, "rf")
end

local ok, err = xpcall(function()
  -- Create a project with a nested CMakeLists.txt.
  write(vim.fs.joinpath(root, "CMakeLists.txt"))
  write(vim.fs.joinpath(nested, "CMakeLists.txt"))
  write(source, "int main() { return 0; }")

  local buf = buffer_for(source)
  local found, root_err = cmake.root(buf)

  equal(root_err, nil, "Nested project error")
  equal(found, root, "Outermost CMake root")

  -- An unnamed buffer must be rejected.
  local unnamed = buffer_for(nil)
  local unnamed_root, unnamed_err = cmake.root(unnamed)

  equal(unnamed_root, nil, "Unnamed buffer root")
  equal(unnamed_err, "Buffer has no file path; save it first", "Unnamed buffer error")

  -- An invalid buffer must be rejected.
  local invalid_root, invalid_err = cmake.root(999999)

  equal(invalid_root, nil, "Invalid buffer root")
  equal(invalid_err, "Invalid buffer", "Invalid buffer error")

  -- A file outside a CMake project must be rejected.
  write(no_project, "int main() { return 0; }")

  local no_project_buf = buffer_for(no_project)
  local missing_root, missing_err = cmake.root(no_project_buf)

  equal(missing_root, nil, "Missing project root")
  assert(missing_err:match("^No CMake project found above "), "Unexpected missing-project error: " .. tostring(missing_err))

  print("PASS outermost CMake root detection")
  print("PASS unnamed buffer rejection")
  print("PASS invalid buffer rejection")
  print("PASS missing project rejection")
end, debug.traceback)

cleanup()

if not ok then
  error(err)
end
