-- Test optional Clippy integration in the Rust language pack.
--
-- Run:
--   nvim --headless -u .\init.lua -l .\scripts\test-rust-clippy.lua

local rust = require("langs.rust")
local languages = require("config.languages")

local tools = languages.tools

assert(type(tools) == "table", "Language tools configuration is missing")
assert(vim.fn.executable("rust-analyzer") == 1, "rust-analyzer is unavailable")
assert(vim.fn.executable("cargo-clippy") == 1, "cargo-clippy is unavailable")

local function check_command()
  local config = vim.lsp.config.rust_analyzer

  assert(config, "rust-analyzer LSP configuration is missing")

  local settings = config.settings["rust-analyzer"]

  assert(settings and settings.check, "Rust Analyzer check settings are missing")

  return settings.check.command
end

local original_value = tools.rust_clippy

local function run_tests()
  -- Verify the default configuration.
  tools.rust_clippy = false
  rust.setup()

  local default_command = check_command()

  print("Clippy disabled:", default_command)

  assert(
    default_command == "check",
    "Expected cargo check when Clippy is disabled"
  )

  -- Enable optional Clippy.
  tools.rust_clippy = true
  rust.setup()

  local clippy_command = check_command()

  print("Clippy enabled:", clippy_command)

  assert(
    clippy_command == "clippy",
    "Expected cargo clippy when Clippy is enabled"
  )

  -- Restore and verify the default behavior.
  tools.rust_clippy = false
  rust.setup()

  local restored_command = check_command()

  print("Default restored:", restored_command)

  assert(
    restored_command == "check",
    "Expected cargo check after restoring the default"
  )
end

-- Restore the original in-memory setting, even if a test fails.
local ok, err = xpcall(run_tests, debug.traceback)

tools.rust_clippy = original_value
rust.setup()

if not ok then
  error(err)
end

print("PASS: Optional Rust Clippy configuration works")
