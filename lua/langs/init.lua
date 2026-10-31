-- Stage 10: Language-pack registry.
-- Discover language packs from this configuration only.
-- Stage 11: Aggregate language-specific metadata without changing setup behavior.

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

function M.setup()
  for _, name in ipairs(discover_packs()) do
    local pack = require("langs." .. name)

    assert(type(pack.setup) == "function", string.format("Language pack 'langs.%s' must provide setup()", name))

    pack.setup()
  end
end

-- Collect metadata declared by language packs.
-- Each key must have exactly one owning pack; silent overrides are not allowed.
function M.collect(field)
  assert(type(field) == "string" and field ~= "", "field must be a non-empty string")

  local merged = {}

  for _, name in ipairs(discover_packs()) do
    local pack = require("langs." .. name)
    local metadata = pack[field]

    if metadata ~= nil then
      assert(type(metadata) == "table", string.format("Language pack 'langs.%s': '%s' must be a table", name, field))

      for key, value in pairs(metadata) do
        assert(type(key) == "string" and key ~= "", string.format("Language pack 'langs.%s': '%s' keys must be non-empty strings", name, field))

        assert(rawget(merged, key) == nil, string.format("Language packs define '%s' for '%s' more than once", field, key))

        merged[key] = value
      end
    end
  end

  return merged
end

return M
