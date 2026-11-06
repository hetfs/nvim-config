
-- Stage 11: Shell formatting through shfmt.
--
-- Use project .editorconfig settings when available.
-- Fall back to four-space indentation and case indentation.
-- The target filename is passed to shfmt for EditorConfig resolution.

local M = {}

--- Return shfmt fallback arguments when no ancestor .editorconfig exists.
---
--- Project .editorconfig files take precedence over fallback arguments.
--- stop limits the upward search for isolated tests.
function M.shfmt_args(filename, stop)
  if type(filename) ~= "string" or filename == "" then
    error("shfmt_args requires a non-empty filename", 2)
  end

  local found = vim.fs.find(".editorconfig", {
    path = vim.fs.dirname(filename),
    upward = true,
    limit = 1,
    stop = stop,
  })

  if #found > 0 then
    return {}
  end

  return {
    "-i",
    "4",
    "-ci",
  }
end

--- Resolve shfmt arguments for the current formatting request.
local function get_args(self, ctx)
  return M.shfmt_args(ctx.filename)
end

return {
  inherit = false,

  command = "shfmt",

  args = function(self, ctx)
    local args = get_args(self, ctx)

    return args
  end,

  stdin = true,
}
