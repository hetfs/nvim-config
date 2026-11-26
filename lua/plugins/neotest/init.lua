vim.pack.add({
  -- Core dependencies
  "https://github.com/nvim-lua/plenary.nvim",
  "https://github.com/nvim-neotest/nvim-nio",
  "https://github.com/nvim-neotest/neotest",

  -- Language adapters
  "https://github.com/nvim-neotest/neotest-python",
  "https://github.com/nvim-neotest/neotest-jest",
  "https://github.com/marilari88/neotest-vitest",
  "https://github.com/nvim-neotest/neotest-go",
  "https://github.com/rouge8/neotest-rust",
  "https://github.com/nvim-neotest/neotest-plenary",
  "https://github.com/MisanthropicBit/neotest-busted",
  "https://github.com/orjangj/neotest-ctest",
  "https://github.com/rcasia/neotest-bash",
})

-- Build adapters
local adapters = require("plugins.neotest.adapters").build()

-- Initialize Neotest
local neotest = require("neotest")

neotest.setup({
  adapters = adapters,
})

-- ============================================================
-- Windows path normalization
-- ============================================================

local is_windows = package.config:sub(1, 1) == "\\"

local function normalize_path(path)
  if is_windows and type(path) == "string" then
    return path:gsub("/", "\\")
  end

  return path
end

-- Normalize paths before Neotest execution.
local original_run = neotest.run.run

neotest.run.run = function(args, ...)
  if type(args) == "string" then
    args = normalize_path(args)
  elseif type(args) == "table" and type(args[1]) == "string" then
    args[1] = normalize_path(args[1])
  elseif args == nil then
    args = { normalize_path(vim.api.nvim_buf_get_name(0)) }
  end

  return original_run(args, ...)
end
