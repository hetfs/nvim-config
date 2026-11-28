-- Stage 27: Window maximization.
-- Temporarily maximize the active split and restore the previous layout.
--
-- Plugin:
--   - vim-maximizer
--
-- Features:
--   - Maximize the current split.
--   - Restore the previous window layout.
--   - Disable the plugin's default <F3> mapping.
--
-- Keymaps:
--   - <leader>sm: Toggle split maximization.

vim.pack.add({
  {
    src = "https://github.com/szw/vim-maximizer",
    name = "vim-maximizer",
  },
})

-- Disable the plugin's default <F3> mappings.
vim.g.maximizer_set_default_mapping = 0

-- ============================================================
-- Keymaps
-- ============================================================

vim.keymap.set("n", "<leader>sm", "<cmd>MaximizerToggle<CR>", {
  desc = "Maximize/minimize split",
})
