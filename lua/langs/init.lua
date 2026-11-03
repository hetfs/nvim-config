
-- Stage 09: Language-pack registry.
-- Discover language packs from this configuration only.
-- Stage 11: Aggregate metadata from enabled language packs.
-- Activation is controlled by lua/config/languages.lua.

local M = {}

local config_root = vim.fn.fnamemodify(vim.fn.resolve(debug.getinfo(1, "S").source:sub(2)), ":p:h:h:h")
local langs_root = config_root .. "/lua/langs"

local function discover_packs()
  local files = vim.fn.globpath(langs_root, "*.lua", false, true)
  local packs = {}

  table.sort(files)

  for _, file in ipairs(files) do
    local name = vim.fn.fnamemodify(file, ":t:r")

    if name ~= "init" then
      packs[#packs + 1] = name
    end
  end

  return packs
end

local function get_enabled_packs()
  local config = require("config.languages")

  assert(type(config) == "table", "Language configuration must return a table")
  assert(type(config.packs) == "table", "Language configuration must define a 'packs' table")

  local discovered = discover_packs()
  local known = {}

  for _, name in ipairs(discovered) do
    known[name] = true
  end

  -- Validate activation entries, including disabled entries.
  for name, enabled in pairs(config.packs) do
    assert(
      type(name) == "string" and name ~= "",
      "Language-pack configuration keys must be non-empty strings"
    )

    assert(
      type(enabled) == "boolean",
      string.format("Language-pack configuration for '%s' must be boolean", name)
    )

    assert(
      known[name],
      string.format("Unknown language pack '%s' in language configuration", name)
    )
  end

  local packs = {}

  for _, name in ipairs(discovered) do
    if config.packs[name] == true then
      packs[#packs + 1] = name
    end
  end

  return packs
end

function M.setup()
  for _, name in ipairs(get_enabled_packs()) do
    local pack = require("langs." .. name)

    assert(
      type(pack.setup) == "function",
      string.format("Language pack 'langs.%s' must provide setup()", name)
    )

    pack.setup()
  end
end

-- Collect metadata declared by enabled language packs.
-- Each key must have exactly one owning pack.
-- Disabled packs do not contribute metadata.
function M.collect(field)
  assert(type(field) == "string" and field ~= "", "field must be a non-empty string")

  local merged = {}

  for _, name in ipairs(get_enabled_packs()) do
    local pack = require("langs." .. name)
    local metadata = pack[field]

    if metadata ~= nil then
      assert(
        type(metadata) == "table",
        string.format("Language pack 'langs.%s': '%s' must be a table", name, field)
      )

      for key, value in pairs(metadata) do
        assert(
          type(key) == "string" and key ~= "",
          string.format("Language pack 'langs.%s': '%s' keys must be non-empty strings", name, field)
        )

        assert(
          rawget(merged, key) == nil,
          string.format("Language packs define '%s' for '%s' more than once", field, key)
        )

        merged[key] = value
      end
    end
  end

  return merged
end

return M

