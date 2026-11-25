-- Stage 12: Git integration.
-- Gitsigns provides Git change indicators and hunk-level workflows.

vim.pack.add({
  {
    src = "https://github.com/lewis6991/gitsigns.nvim",
    name = "gitsigns.nvim",
  },
})

require("gitsigns").setup({
  on_attach = function(bufnr)
    -- Register buffer-local Gitsigns mappings after startup.
    vim.schedule(function()
      local keymaps = require("config.keymaps")

      if type(keymaps.gitsigns) == "function" then
        keymaps.gitsigns(bufnr)
      end
    end)
  end,
})
