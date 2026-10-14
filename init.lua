-- nvim-config
-- Native-first, modular Neovim configuration.
-- Minimum supported version: Neovim 0.12.

if vim.fn.has("nvim-0.12") ~= 1 then
  error(
    string.format(
      "nvim-config requires Neovim >= 0.12.0; detected %s.",
      tostring(vim.version())
    ),
    0
  )
end

-- Stage 01 intentionally contains no plugins or custom modules.
-- Additional configuration will be introduced in subsequent stages.
