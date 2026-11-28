local rust = require("langs.rust")

local cases = {
  {
    name = "standalone crate",
    path = "C:/Users/Administrator/rust-root-test/src/main.rs",
    expected = "C:/Users/Administrator/rust-root-test",
  },
  {
    name = "workspace member",
    path = "C:/Users/Administrator/rust-workspace-test/crates/app/src/main.rs",
    expected = "C:/Users/Administrator/rust-workspace-test",
  },
  {
    name = "excluded package",
    path = "C:/Users/Administrator/rust-root-test/standalone/src/main.rs",
    expected = "C:/Users/Administrator/rust-root-test/standalone",
  },
  {
    name = "nested workspace",
    path = "C:/Users/Administrator/rust-workspace-test/nested/crates/app/src/main.rs",
    expected = "C:/Users/Administrator/rust-workspace-test/nested",
  },
  {
    name = "explicit workspace inheritance",
    path = "C:/Users/Administrator/rust-inherited-test/packages/app/src/main.rs",
    expected = "C:/Users/Administrator/rust-inherited-test/workspace",
  },
  {
    name = "rust-project.json",
    path = "C:/Users/Administrator/rust-project-test/src/main.rs",
    expected = "C:/Users/Administrator/rust-project-test",
  },
}

local failed = 0

for _, case in ipairs(cases) do
  local actual, err = rust.find_root(case.path)

  if actual then
    actual = vim.fs.normalize(actual)
  end

  local expected = vim.fs.normalize(case.expected)

  if actual == expected then
    print("PASS " .. case.name)
  else
    failed = failed + 1
    print("FAIL " .. case.name)
    print("  expected: " .. expected)
    print("  actual:   " .. tostring(actual))

    if err then
      print("  error:    " .. err)
    end
  end
end

if failed > 0 then
  error(string.format("%d Rust root-resolution test(s) failed", failed))
end

print(string.format("Rust root-resolution tests passed: %d", #cases))

