
-- Stage 29: ANSI terminal output highlighting.
-- Conceal ANSI escape sequences and render their colors.
--
-- Plugin:
--   - vim-plugin-AnsiEsc
--
-- Features:
--   - Highlight ANSI terminal color sequences.
--   - Conceal escape codes.
--   - Preserve readable terminal output.
--
-- Commands:
--   - :AnsiEsc

vim.pack.add({
  {
    src = "https://github.com/powerman/vim-plugin-AnsiEsc",
    name = "vim-plugin-AnsiEsc",
  },
})

-- ============================================================
-- Lazy command loading
-- ============================================================

vim.api.nvim_create_user_command("AnsiEsc", function()
  -- The command is provided by the plugin itself.
  -- This placeholder is not needed when the plugin is loaded
  -- normally through vim.pack.
end, {
  desc = "Highlight ANSI escape sequences",
})
