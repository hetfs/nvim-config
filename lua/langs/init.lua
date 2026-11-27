-- Stage 09: Language-pack registry.
-- Discover language packs from this configuration only.
-- Stage 11: Aggregate metadata from enabled language packs.
-- Activation is controlled by lua/config/languages.lua.
--
-- Supported layouts:
--   lua/langs/name.lua
--   lua/langs/name/name.lua

local M = {}

local source = debug.getinfo(1, "S").source

assert(source:sub(1, 1) == "@", "Could not determine the language registry module path")

local module_path = vim.fn.resolve(source:sub(2))
local config_root = vim.fn.fnamemodify(module_path, ":p:h:h:h")
local langs_root = vim.fs.joinpath(config_root, "lua", "langs")

-- Return the absolute root of this Neovim configuration.
function M.root()
  return config_root
end

-- Discover language packs and resolve their module paths.
local function discover_packs()
  local packs = {}
  local modules = {}

  for name, entry_type in vim.fs.dir(langs_root) do
    if entry_type == "file" and name:match("%.lua$") then
      local pack_name = name:gsub("%.lua$", "")

      if pack_name ~= "init" then
        assert(modules[pack_name] == nil, string.format("Duplicate language-pack entry point '%s'", pack_name))

        modules[pack_name] = "langs." .. pack_name
      end
    elseif entry_type == "directory" then
      local nested_entry = vim.fs.joinpath(langs_root, name, name .. ".lua")

      if vim.fn.filereadable(nested_entry) == 1 then
        assert(modules[name] == nil, string.format("Duplicate language-pack entry point '%s'", name))

        modules[name] = "langs." .. name .. "." .. name
      end
    end
  end

  for name in pairs(modules) do
    packs[#packs + 1] = name
  end

  table.sort(packs)

  return packs, modules
end

local function get_enabled_packs()
  local config = require("config.languages")

  assert(type(config) == "table", "Language configuration must return a table")

  assert(type(config.packs) == "table", "Language configuration must define a 'packs' table")

  local discovered, modules = discover_packs()
  local known = {}

  for _, name in ipairs(discovered) do
    known[name] = true
  end

  -- Validate activation entries, including disabled entries.
  for name, enabled in pairs(config.packs) do
    assert(type(name) == "string" and name ~= "", "Language-pack configuration keys must be non-empty strings")

    assert(type(enabled) == "boolean", string.format("Language-pack configuration for '%s' must be boolean", name))

    assert(known[name], string.format("Unknown language pack '%s' in language configuration", name))
  end

  local packs = {}

  -- Preserve deterministic discovery order.
  for _, name in ipairs(discovered) do
    if config.packs[name] == true then
      packs[#packs + 1] = name
    end
  end

  return packs, modules
end

-- Check whether a language pack is enabled.
function M.is_enabled(name)
  assert(type(name) == "string" and name ~= "", "Language-pack name must be a non-empty string")

  for _, enabled_name in ipairs(get_enabled_packs()) do
    if enabled_name == name then
      return true
    end
  end

  return false
end

-- Run optional setup functions from enabled language packs.
-- Metadata-only packs do not need to implement setup().
function M.setup()
  local packs, modules = get_enabled_packs()

  for _, name in ipairs(packs) do
    local pack = require(modules[name])

    assert(type(pack) == "table", string.format("Language pack '%s' must return a table", modules[name]))

    if pack.setup ~= nil then
      assert(type(pack.setup) == "function", string.format("Language pack '%s': setup must be a function", modules[name]))

      pack.setup()
    end
  end
end

-- Collect metadata declared by enabled language packs.
-- Each key must have exactly one owning pack.
-- Disabled packs do not contribute metadata.
function M.collect(field)
  assert(type(field) == "string" and field ~= "", "field must be a non-empty string")

  local merged = {}
  local packs, modules = get_enabled_packs()

  for _, name in ipairs(packs) do
    local pack = require(modules[name])

    assert(type(pack) == "table", string.format("Language pack '%s' must return a table", modules[name]))

    local metadata = pack[field]

    if metadata ~= nil then
      assert(type(metadata) == "table", string.format("Language pack '%s': '%s' must be a table", modules[name], field))

      for key, value in pairs(metadata) do
        assert(type(key) == "string" and key ~= "", string.format("Language pack '%s': '%s' keys must be non-empty strings", modules[name], field))

        assert(rawget(merged, key) == nil, string.format("Language packs define '%s' for '%s' more than once", field, key))

        merged[key] = value
      end
    end
  end

  return merged
end

return M
