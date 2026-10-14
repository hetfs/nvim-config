-- Usage: nvim -u init.lua -l scripts/smoke.lua

local version = vim.version()

assert(
  vim.fn.has("nvim-0.12") == 1,
  string.format(
    "Expected Neovim >= 0.12.0; detected %d.%d.%d.",
    version.major,
    version.minor,
    version.patch
  )
)

print(
  string.format(
    "PASS nvim-config smoke test on Neovim %d.%d.%d",
    version.major,
    version.minor,
    version.patch
  )
)
