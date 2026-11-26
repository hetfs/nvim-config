local M = {}

-- ============================================================
-- Adapter specifications
-- ============================================================

local specs = {
  {
    name = "python",
    module = "neotest-python",
    init = function(mod)
      return mod({
        runner = "pytest",

        -- Resolve Python explicitly to avoid empty-string fallback
        -- from neotest-python's executable detection on Windows.
        python = function()
          return vim.fn.exepath("python")
        end,

        -- Normalize test-file detection across operating systems.
        is_test_file = function(file_path)
          if not vim.endswith(file_path, ".py") then
            return false
          end

          local file_name = vim.fs.basename(file_path)

          return vim.startswith(file_name, "test_") or vim.endswith(file_name, "_test.py")
        end,
      })
    end,
  },

  {
    name = "jest",
    module = "neotest-jest",
    init = function(mod)
      return mod({})
    end,
  },

  {
    name = "vitest",
    module = "neotest-vitest",
    init = function(mod)
      return mod({})
    end,
  },

  {
    name = "go",
    module = "neotest-go",
    init = function(mod)
      return mod({})
    end,
  },

  {
    name = "rust",
    module = "neotest-rust",
    init = function(mod)
      return mod({})
    end,
  },

  {
    name = "plenary",
    module = "neotest-plenary",
    init = function(mod)
      return mod
    end,
  },

  {
    name = "busted",
    module = "neotest-busted",
    init = function(mod)
      return mod({})
    end,
  },

  {
    name = "ctest",
    module = "neotest-ctest",
    init = function(mod)
      return mod.setup({})
    end,
  },

  {
    name = "bash",
    module = "neotest-bash",
    init = function(mod)
      return mod
    end,
  },
}

-- ============================================================
-- Public API
-- ============================================================

function M.build()
  local adapters = {}

  for _, spec in ipairs(specs) do
    local loaded, mod = pcall(require, spec.module)

    if not loaded then
      error(("neotest: failed to load %s: %s"):format(spec.module, tostring(mod)))
    end

    local initialized, adapter = pcall(spec.init, mod)

    if not initialized then
      error(("neotest: failed to initialize %s: %s"):format(spec.name, tostring(adapter)))
    end

    if type(adapter) ~= "table" then
      error(("neotest: invalid adapter returned by %s: %s"):format(spec.name, type(adapter)))
    end

    table.insert(adapters, adapter)
  end

  return adapters
end

return M
