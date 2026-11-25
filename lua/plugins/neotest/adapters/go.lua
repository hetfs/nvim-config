-- Neotest Go adapter.
-- Go test discovery and execution through the Go toolchain.

local M = {}

local adapter

function M.find_root(path)
  if not path or path == "" then
    return nil
  end

  local directory = vim.fn.isdirectory(path) == 1 and path or vim.fs.dirname(path)

  if not directory then
    return nil
  end

  local found = vim.fs.find("go.mod", {
    path = directory,
    upward = true,
    limit = 1,
    type = "file",
  })

  if #found == 0 then
    return nil
  end

  return vim.fs.dirname(found[1])
end

function M.get_adapters()
  if not adapter then
    adapter = require("neotest-go")
  end

  return { adapter }
end

return M
