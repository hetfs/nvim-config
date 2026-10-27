-- User-defined language and formatting preferences.
--
-- Language packs own their default formatter definitions.
-- This module allows users to customize formatter selection without
-- modifying individual language packs.
--
-- Formatter names must match Conform's registered formatter names.
--
-- Policy:
--   preferred:
--     Place preferred formatters before language-pack defaults.
--     Preserve the specified order and remove duplicates.
--
--   stop_after_first:
--     Stop after the first available formatter for the specified filetype.
--
--   formatters_only:
--     Use only the preferred formatter list for the specified filetype.
--     A filetype enabled here must have a non-empty preferred list.
--
--   format_on_save:
--     Configure Conform's format-on-save behavior.
--     Disabled by default; manual :Format remains available.
--
-- These settings control formatter selection and execution policy.
-- They do not install formatter executables.

return {
  formatters = {
    -- Preferred formatter order, keyed by filetype.
    --
    -- Example:
    --   markdown = { "prettier" }
    --
    -- Preferred formatters precede language-pack defaults.
    preferred = {},

    -- Stop after the first available formatter, keyed by filetype.
    --
    -- Example:
    --   javascript = true
    --
    -- This is separate from formatter selection.
    stop_after_first = {},

    -- Restrict a filetype to its preferred formatter list.
    --
    -- Example:
    --   markdown = true
    --
    -- When enabled, the filetype must also have a non-empty entry
    -- in preferred. Language-pack defaults will not be appended.
    formatters_only = {},
  },

  -- Automatic formatting before saving.
  --
  -- Disabled by default. Users can set enabled = true to opt in.
  -- timeout_ms controls how long Conform waits for formatting.
  --
  -- Manual :Format remains available regardless of this setting.
  format_on_save = {
    enabled = false,
    timeout_ms = 500,
  },
}
