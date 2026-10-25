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
    -- Defer the lookup until startup has loaded the central keymap module.
    vim.schedule(function()
      require("config.keymaps").gitsigns(bufnr)
    end)
  end,
})
