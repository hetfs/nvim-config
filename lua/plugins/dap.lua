-- Stage 14: Debugging.
-- nvim-dap provides the core Debug Adapter Protocol client.
-- Debugger adapters and executables are managed separately.

vim.pack.add({
  {
    src = "https://github.com/mfussenegger/nvim-dap",
    name = "nvim-dap",
  },
})
