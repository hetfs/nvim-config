-- User-defined language and formatting preferences.
--
-- Language packs own their default formatter definitions.
-- This module allows users to customize formatter selection,
-- language-pack activation, and formatting policy.
--
-- Policy:
--   packs:
--     Enable or disable individual language packs.
--     Only explicitly enabled packs are initialized.
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

    -- html = false,
    -- css = false,
    -- javascript = false,
    -- typescript = false,
  },

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
