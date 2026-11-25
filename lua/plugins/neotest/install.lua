-- Neotest
-- Core and language adapter installation.

local M = {}

function M.install()
  vim.pack.add({
    -- Core dependencies.
    "https://github.com/nvim-lua/plenary.nvim",
    {
      src = "https://github.com/nvim-neotest/nvim-nio",
      name = "nvim-nio",
    },

    -- CursorHold event support.
    "https://github.com/antoinemadec/FixCursorHold.nvim",

    -- Neotest.
    {
      src = "https://github.com/nvim-neotest/neotest",
      name = "neotest",
    },

    -- Python.
    {
      src = "https://github.com/nvim-neotest/neotest-python",
      name = "neotest-python",
    },

    -- JavaScript / TypeScript.
    {
      src = "https://github.com/nvim-neotest/neotest-jest",
      name = "neotest-jest",
    },
    {
      src = "https://github.com/marilari88/neotest-vitest",
      name = "neotest-vitest",
    },

    -- Remaining language adapters.
    {
      src = "https://github.com/nvim-neotest/neotest-go",
      name = "neotest-go",
    },
    {
      src = "https://github.com/rouge8/neotest-rust",
      name = "neotest-rust",
    },
    {
      src = "https://github.com/nvim-neotest/neotest-plenary",
      name = "neotest-plenary",
    },
    {
      src = "https://github.com/MisanthropicBit/neotest-busted",
      name = "neotest-busted",
    },
    {
      src = "https://github.com/orjangj/neotest-ctest",
      name = "neotest-ctest",
    },
    {
      src = "https://github.com/rcasia/neotest-bash",
      name = "neotest-bash",
    },
  })
end

return M
