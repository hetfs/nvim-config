local conform = require("conform")

local formatter = assert(
  conform.get_formatter_config("rustfmt"),
  "Conform rustfmt configuration is missing"
)

assert(
  formatter.options.default_edition == "2024",
  "Expected Rust edition fallback to be 2024"
)

local root = vim.fn.tempname()
local fallback_dir = vim.fn.tempname()

local function cleanup()
  vim.fn.delete(root, "rf")
  vim.fn.delete(fallback_dir, "rf")
end

local function formatter_args(dirname)
  return formatter.args(formatter, {
    dirname = dirname,
  })
end

local function run_tests()
  vim.fn.mkdir(root, "p")

  vim.fn.writefile({
    "[package]",
    'name = "rust_edition_test"',
    'version = "0.1.0"',
    'edition = "2021"',
  }, vim.fs.joinpath(root, "Cargo.toml"))

  -- An explicit project edition must override the fallback.
  local project_args = formatter_args(root)

  print("Project formatter arguments:", vim.inspect(project_args))

  assert(
    vim.tbl_contains(project_args, "--edition=2021"),
    "Explicit Cargo edition 2021 was not respected"
  )

  -- A directory outside the project tree must use the configured fallback.
  vim.fn.mkdir(fallback_dir, "p")

  local fallback_args = formatter_args(fallback_dir)

  print("Fallback formatter arguments:", vim.inspect(fallback_args))

  assert(
    vim.tbl_contains(fallback_args, "--edition=2024"),
    "Expected default Rust edition 2024"
  )

  print("PASS: Rust formatter edition resolution works")
end

local ok, err = xpcall(run_tests, debug.traceback)

cleanup()

if not ok then
  error(err)
end
