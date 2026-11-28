-- Test clangd source/header switching through the C/C++ buffer-local mapping.

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

local keymaps = require("config.keymaps")

local original_get_clients = vim.lsp.get_clients
local original_notify = vim.notify
local original_current_buf = vim.api.nvim_get_current_buf()

local notifications = {}
local test_buffers = {}
local test_files = {}
local checks = 0

local SWITCH_METHOD = "textDocument/switchSourceHeader"

local function check(condition, description)
  if not condition then
    error("FAIL " .. description, 2)
  end

  checks = checks + 1
  print("PASS " .. description)
end

local function reset_notifications()
  notifications = {}

  vim.notify = function(message, level)
    notifications[#notifications + 1] = {
      message = message,
      level = level,
    }
  end
end

local function last_notification()
  return notifications[#notifications]
end

local function create_buffer()
  local bufnr = vim.api.nvim_create_buf(true, false)
  local filename = vim.fn.tempname() .. ".c"

  vim.api.nvim_buf_set_name(bufnr, filename)
  vim.bo[bufnr].filetype = "c"

  test_buffers[#test_buffers + 1] = bufnr

  keymaps.c_cpp(bufnr)

  return bufnr
end

local function get_switch_callback(bufnr)
  local lhs = vim.g.mapleader .. "ch"

  return vim.api.nvim_buf_call(bufnr, function()
    local mapping = vim.fn.maparg(lhs, "n", false, true)
    return mapping and mapping.callback
  end)
end

local function create_client(options)
  options = options or {}

  local client = {
    supports_method = function()
      return options.supports_method ~= false
    end,
  }

  -- Capture request arguments without assuming dot or colon invocation.
  client.request = function(...)
    local args = { ... }

    for index, value in ipairs(args) do
      if value == SWITCH_METHOD then
        options.method = value
        options.params = args[index + 1]
        options.callback = args[index + 2]
        options.bufnr = args[index + 3]
        break
      end
    end

    return options.request_result ~= false
  end

  return client, options
end

local function attach_client(client)
  vim.lsp.get_clients = function()
    return { client }
  end
end

local function cleanup()
  vim.lsp.get_clients = original_get_clients
  vim.notify = original_notify

  -- Restore the original current buffer when it still exists.
  if vim.api.nvim_buf_is_valid(original_current_buf) then
    pcall(vim.api.nvim_set_current_buf, original_current_buf)
  end

  for _, bufnr in ipairs(test_buffers) do
    if vim.api.nvim_buf_is_valid(bufnr) then
      pcall(vim.api.nvim_buf_delete, bufnr, {
        force = true,
      })
    end
  end

  for _, filename in ipairs(test_files) do
    vim.fn.delete(filename)
  end
end

local function run_tests()
  reset_notifications()

  -- Create a buffer and retrieve the registered mapping callback.
  local bufnr = create_buffer()
  local callback = get_switch_callback(bufnr)

  check(type(callback) == "function", "Source/header mapping exposes a callable callback")

  -- No clangd client attached.
  vim.lsp.get_clients = function()
    return {}
  end

  callback()

  local notification = last_notification()

  check(notification and notification.message:match("clangd is not attached"), "Missing clangd client reports a warning")

  -- clangd does not support the method.
  reset_notifications()

  attach_client(create_client({
    supports_method = false,
  }))

  callback()

  notification = last_notification()

  check(notification and notification.message:match("does not support source/header switching"), "Unsupported method reports a warning")

  -- clangd rejects the request.
  reset_notifications()

  local rejected, rejected_request = create_client({
    request_result = false,
  })

  attach_client(rejected)
  callback()

  notification = last_notification()

  check(notification and notification.message:match("rejected the source/header switch request"), "Rejected LSP request reports a warning")

  check(rejected_request.method == SWITCH_METHOD, "Source/header switching uses the clangd extension method")

  check(type(rejected_request.params) == "table" and rejected_request.params.uri == vim.uri_from_bufnr(bufnr), "LSP request uses the original buffer URI")

  check(rejected_request.bufnr == bufnr, "LSP request is associated with the original buffer")

  -- Callback returns an error.
  reset_notifications()

  local failed, failed_request = create_client()
  attach_client(failed)
  callback()

  check(type(failed_request.callback) == "function", "LSP request registers a callback")

  failed_request.callback({
    message = "simulated clangd failure",
  }, nil)

  notification = last_notification()

  check(notification and notification.message:match("simulated clangd failure"), "LSP callback errors are reported")

  -- No matching source/header file.
  reset_notifications()

  local unmatched, unmatched_request = create_client()
  attach_client(unmatched)
  callback()

  unmatched_request.callback(nil, nil)

  notification = last_notification()

  check(notification and notification.message:match("No matching source/header file found"), "Missing matching file is reported")

  -- Original buffer becomes invalid before the callback completes.
  reset_notifications()

  local invalidated, invalidated_request = create_client()
  attach_client(invalidated)
  callback()

  vim.api.nvim_buf_delete(bufnr, {
    force = true,
  })

  invalidated_request.callback(nil, "file:///tmp/unused.h")

  notification = last_notification()

  check(notification and notification.message:match("Original buffer is no longer valid"), "Invalid original buffer prevents switching")

  -- Successful switch using a real temporary header file.
  reset_notifications()

  local success_buf = create_buffer()
  local success_callback = get_switch_callback(success_buf)

  local header_path = vim.fn.tempname() .. ".h"

  test_files[#test_files + 1] = header_path

  vim.fn.writefile({
    "#pragma once",
    "int smoke_test(void);",
  }, header_path)

  local successful, successful_request = create_client()
  attach_client(successful)

  -- Run the mapping from its target buffer, as a user would.
  vim.api.nvim_set_current_buf(success_buf)

  success_callback()

  check(type(successful_request.callback) == "function", "Successful LSP request registers a callback")

  successful_request.callback(nil, vim.uri_from_fname(header_path))

  check(vim.api.nvim_buf_is_valid(success_buf), "Original buffer remains valid after switching")

  check(vim.api.nvim_buf_get_name(0) == header_path, "Successful callback opens the returned header in the current window")

  check(#notifications == 0, "Successful switch does not report an error")

  print(string.format("%d clangd source/header checks passed", checks))
end

local ok, err = xpcall(run_tests, debug.traceback)

cleanup()

if not ok then
  error(err)
end
