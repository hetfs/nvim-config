-- Stage 09: Language-pack registry.
-- Discover language packs from this configuration only.

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

return M
