-- Stage 11: Formatting through Conform.
--
-- Language packs own their default formatter definitions.
-- User preferences are declared in config.languages.
-- This module resolves both into Conform's formatters_by_ft configuration.
--
-- Manual formatting through :Format is always available.
-- Format-on-save is disabled by default and can be enabled by the user.
-- LSP formatting fallback is disabled.

local M = {}

local formatters_by_ft

local function fail(message)
  error("Formatting configuration: " .. message, 3)
end

local function validate_filetype_map(value, name, validate_value)
  if type(value) ~= "table" then
    fail(name .. " must be a table")
  end

  for filetype, entry in pairs(value) do
    if type(filetype) ~= "string" or filetype == "" then
      fail(name .. " keys must be non-empty filetype strings")
    end

    validate_value(entry, filetype)
  end
end

local function validate_formatter_list(value, name)
  if type(value) ~= "table" then
    fail(name .. " must be a list of formatter names")
  end

  local count = 0
  local maximum = 0

  for key, formatter in pairs(value) do
    if type(key) ~= "number" or key < 1 or key % 1 ~= 0 then
      fail(name .. " must contain only sequential numeric list entries")
    end

    if type(formatter) ~= "string" or formatter == "" then
      fail(name .. " must contain only non-empty formatter names")
    end

    count = count + 1
    maximum = math.max(maximum, key)
  end

  if count ~= maximum then
    fail(name .. " must not contain gaps in its formatter list")
  end

  return value
end

local function validate_boolean_map(value, name)
  validate_filetype_map(value, name, function(entry, filetype)
    if type(entry) ~= "boolean" then
      fail(string.format("%s.%s must be a boolean", name, filetype))
    end
  end)
end

local function append_unique(result, seen, formatter)
  if not seen[formatter] then
    result[#result + 1] = formatter
    seen[formatter] = true
  end
end

local function copy_unique(formatters)
  local result = {}
  local seen = {}

  for _, formatter in ipairs(formatters) do
    append_unique(result, seen, formatter)
  end

  return result
end

local function get_preference_map(preferences, key)
  local value = preferences[key]

  if value == nil then
    return {}
  end

  if type(value) ~= "table" then
    fail("config.languages.formatters." .. key .. " must be a table")
  end

  return value
end

local function get_format_on_save_config(language_config)
  local config = language_config.format_on_save

  if config == nil then
    return nil
  end

  if type(config) ~= "table" then
    fail("config.languages.format_on_save must be a table")
  end

  local enabled = config.enabled

  if enabled == nil then
    enabled = false
  elseif type(enabled) ~= "boolean" then
    fail("config.languages.format_on_save.enabled must be a boolean")
  end

  local timeout_ms = config.timeout_ms

  if timeout_ms == nil then
    timeout_ms = 500
  elseif type(timeout_ms) ~= "number" or timeout_ms < 1 or timeout_ms % 1 ~= 0 then
    fail("config.languages.format_on_save.timeout_ms must be a positive integer")
  end

  if not enabled then
    return nil
  end

  return {
    timeout_ms = timeout_ms,
    lsp_format = "never",
  }
end

-- Resolve language-pack defaults and user-defined formatter preferences.
--
-- Optional arguments make the resolver independently testable.
--
-- defaults:
--   Formatter metadata collected from language packs.
--
-- preferences:
--   The formatters table from config.languages.
--
-- User policy:
--   preferred:
--     Preferred formatters precede language-pack defaults.
--     Duplicate names are removed while preserving order.
--
--   stop_after_first:
--     Stop after the first available formatter for the filetype.
--
--   formatters_only:
--     Use only the preferred formatter list for that filetype.
--     An enabled filetype must have a non-empty preferred list.
function M.resolve(defaults, preferences)
  if defaults == nil then
    defaults = require("langs").collect("formatters")
  end

  if preferences == nil then
    local language_config = require("config.languages")

    if type(language_config) ~= "table" then
      fail("config.languages must return a table")
    end

    preferences = language_config.formatters
  end

  if type(defaults) ~= "table" then
    fail("language-pack formatter metadata must be a table")
  end

  if type(preferences) ~= "table" then
    fail("config.languages.formatters must be a table")
  end

  local preferred = get_preference_map(preferences, "preferred")
  local stop_after_first = get_preference_map(preferences, "stop_after_first")
  local formatters_only = get_preference_map(preferences, "formatters_only")

  validate_filetype_map(defaults, "language-pack formatters", function(formatters, filetype)
    validate_formatter_list(formatters, "language-pack formatters." .. filetype)
  end)

  validate_filetype_map(preferred, "config.languages.formatters.preferred", function(formatters, filetype)
    validate_formatter_list(formatters, "config.languages.formatters.preferred." .. filetype)
  end)

  validate_boolean_map(stop_after_first, "config.languages.formatters.stop_after_first")

  validate_boolean_map(formatters_only, "config.languages.formatters.formatters_only")

  -- formatters_only requires an explicit, non-empty preferred list.
  for filetype, enabled in pairs(formatters_only) do
    if enabled then
      local configured = preferred[filetype]

      if not configured or #configured == 0 then
        fail(string.format("formatters_only.%s is true, but preferred.%s has no formatter names", filetype, filetype))
      end
    end
  end

  local result = {}

  -- Resolve filetypes with language-pack defaults.
  for filetype, defaults_for_filetype in pairs(defaults) do
    local preferred_for_filetype = preferred[filetype] or {}
    local resolved = copy_unique(preferred_for_filetype)

    if not formatters_only[filetype] then
      local seen = {}

      for _, formatter in ipairs(resolved) do
        seen[formatter] = true
      end

      for _, formatter in ipairs(defaults_for_filetype) do
        append_unique(resolved, seen, formatter)
      end
    end

    result[filetype] = resolved
  end

  -- Also include filetypes defined only by user preferences.
  for filetype, preferred_for_filetype in pairs(preferred) do
    if result[filetype] == nil then
      result[filetype] = copy_unique(preferred_for_filetype)
    end
  end

  -- Apply Conform's per-filetype stop_after_first option.
  for filetype, enabled in pairs(stop_after_first) do
    if enabled then
      local configured = result[filetype]

      if not configured or #configured == 0 then
        fail(string.format("stop_after_first.%s is true, but no formatter is configured for that filetype", filetype))
      end

      configured.stop_after_first = true
    end
  end

  return result
end

function M.format()
  local conform = require("conform")
  local bufnr = vim.api.nvim_get_current_buf()
  local filetype = vim.bo[bufnr].filetype
  local configured = formatters_by_ft[filetype]

  if not configured or #configured == 0 then
    vim.notify(string.format("Format: no formatter configured for '%s'", filetype ~= "" and filetype or "unknown"), vim.log.levels.WARN)
    return
  end

  local available = conform.list_formatters_to_run(bufnr)

  if #available == 0 then
    local unavailable = {}

    for _, name in ipairs(configured) do
      local info = conform.get_formatter_info(name, bufnr)

      if not info or not info.available then
        unavailable[#unavailable + 1] = name
      end
    end

    if #unavailable > 0 then
      vim.notify(string.format("Format: formatter executable unavailable: %s", table.concat(unavailable, ", ")), vim.log.levels.WARN)
    else
      vim.notify(
        string.format("Format: no configured formatter is runnable for '%s' in this buffer", filetype ~= "" and filetype or "unknown"),
        vim.log.levels.WARN
      )
    end

    return
  end

  conform.format({
    bufnr = bufnr,
    async = true,
    lsp_format = "never",
  })
end

function M.setup()
  local language_config = require("config.languages")

  if type(language_config) ~= "table" then
    fail("config.languages must return a table")
  end

  formatters_by_ft = M.resolve(nil, language_config.formatters)

  local conform_config = {
    formatters_by_ft = formatters_by_ft,
    default_format_opts = {
      lsp_format = "never",
    },
  }

  -- Conform registers its save hook only when explicitly enabled.
  conform_config.format_on_save = get_format_on_save_config(language_config)

  require("conform").setup(conform_config)

  vim.api.nvim_create_user_command("Format", M.format, {
    desc = "Format current buffer",
  })
end

return M
