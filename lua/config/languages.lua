-- User-defined language and formatting preferences.
--
-- Language packs own their default formatter definitions.
-- This module allows users to customize formatter selection,
-- language-pack activation, tool integration, and formatting policy.
--
-- Policy:
--   packs:
--     Enable or disable individual language packs.
--     Only explicitly enabled packs are initialized.
--
--   tools:
--     Enable or disable optional shared tools independently
--     of language-pack activation.
--
--   formatters:
--     preferred:
--       Place preferred formatters before language-pack defaults.
--       Preserve the specified order and remove duplicates.
--
--     stop_after_first:
--       Stop after the first available formatter for the specified filetype.
--
--     formatters_only:
--       Use only the preferred formatter list for the specified filetype.
--
--   format_on_save:
--     Configure Conform's format-on-save behavior.
--     Disabled by default; manual :Format remains available.

return {
  -- Language-pack activation.
  --
  -- Only explicitly enabled packs are initialized.
  -- Omitted packs are disabled.
  packs = {
    lua = true,
    python = true,
    data = true,
    c = true,
    cpp = true,
    html = true,
    css = true,
    javascript = true,
    typescript = true,
    powershell = true,
    shell = true,
    rust = true,
    sql = true,
    docker = true,
    markdown = true,
    mdx = true,
    latex = true,
    go = true,
  },

  -- Optional shared tool integrations.
  --
  -- These are independent of language-pack activation.
  tools = {
    emmet = false,

    -- Use Clippy instead of cargo check for rust-analyzer diagnostics.
    -- Requires: rustup component add clippy
    rust_clippy = false,
  },

  -- Formatter preferences.
  formatters = {
    -- Preferred formatter order, keyed by filetype.
    preferred = {},

    -- Stop after the first available formatter, keyed by filetype.
    stop_after_first = {},

    -- Restrict a filetype to its preferred formatter list.
    formatters_only = {},
  },

  -- Automatic formatting before saving.
  -- Disabled by default.
  format_on_save = {
    enabled = false,
    timeout_ms = 500,
  },
}
