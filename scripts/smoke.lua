-- Usage: nvim --headless -u init.lua -l scripts/smoke.lua
-- Or:    nvim --headless -u init.lua "+luafile scripts/smoke.lua"

local MIN_VERSION = "nvim-0.12"
local AUGROUP = "nvim_config"
local MIN_AUTOCMDS = 3

local version = vim.version()
local version_string = string.format("%d.%d.%d", version.major, version.minor, version.patch)

local failures = {}

local function check(condition, message)
  if not condition then
    failures[#failures + 1] = message
  end
end

-- The minimum supported Neovim version is a hard requirement.
assert(
  vim.fn.has(MIN_VERSION) == 1,
  string.format("Expected Neovim >= 0.12.0; detected %s.", version_string)
)

-- Verify window-local options.
check(vim.wo.number, "Line numbers should be enabled")
check(vim.wo.relativenumber, "Relative line numbers should be enabled")

-- Verify buffer-local options.
check(vim.bo.expandtab, "Spaces should be used for indentation")
check(vim.bo.shiftwidth == 2, "Shift width should be 2")

-- Verify global options.
check(vim.o.splitright, "Vertical splits should open to the right")
check(vim.o.splitbelow, "Horizontal splits should open below")

-- Verify Stage 02 configuration modules were loaded.
for _, module in ipairs({
  "config.options",
  "config.keymaps",
  "config.autocmds",
}) do
  check(
    package.loaded[module] ~= nil,
    string.format("Configuration module was not loaded: %s", module)
  )
end

-- Verify representative normal-mode mappings by description.
local function has_mapping_with_desc(mode, description)
  for _, mapping in ipairs(vim.api.nvim_get_keymap(mode)) do
    if mapping.desc == description then
      return true
    end
  end

  return false
end

for _, description in ipairs({
  "Save file",
  "Focus left window",
}) do
  check(
    has_mapping_with_desc("n", description),
    string.format("Normal-mode mapping with description '%s' is missing", description)
  )
end

-- Verify the expected autocommand group.
local ok, autocmds = pcall(vim.api.nvim_get_autocmds, {
  group = AUGROUP,
})

if not ok then
  check(
    false,
    string.format("Unable to retrieve autocommands for group '%s': %s", AUGROUP, tostring(autocmds))
  )
else
  check(
    #autocmds >= MIN_AUTOCMDS,
    string.format(
      "Expected at least %d autocommands in '%s'; found %d",
      MIN_AUTOCMDS,
      AUGROUP,
      #autocmds
    )
  )
end

-- Report all failures and exit non-zero.
if #failures > 0 then
  io.stderr:write(
    string.format(
      "FAIL nvim-config Stage 02 smoke test (%d issue(s)):\n  - %s\n",
      #failures,
      table.concat(failures, "\n  - ")
    )
  )

  vim.cmd.cquit(1)
end

print(string.format("PASS nvim-config Stage 02 smoke test on Neovim %s", version_string))
