-- User-defined AI integration preferences.
--
-- AI providers are independent of language-pack activation.
--
-- Policy:
--   enabled:
--     Enable or disable AI integrations globally.
--
--   providers:
--     Enable or disable individual AI providers.
--     A provider is initialized only when both the
--     global switch and its provider switch are enabled.

return {
  -- Global AI activation.
  enabled = true,

  -- Individual provider activation.
  providers = {
    blink_edit = false,
    codecompanion = true,
  },
}

