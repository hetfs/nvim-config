vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

local keymaps = require("config.keymaps")

local passed = 0

local function find_map(lhs, bufnr)
  local resolved_lhs = lhs
    :gsub("<leader>", function()
      return vim.g.mapleader
    end)
    :gsub("<localleader>", function()
      return vim.g.maplocalleader
    end)

  local mappings

  if bufnr then
    mappings = vim.api.nvim_buf_get_keymap(bufnr, "n")
  else
    mappings = vim.api.nvim_get_keymap("n")
  end

  for _, mapping in ipairs(mappings) do
    if mapping.lhs == resolved_lhs then
      return mapping
    end
  end
end

local function check(name, callback)
  local ok, err = pcall(callback)

  if not ok then
    error(("FAIL %s: %s"):format(name, err))
  end

  passed = passed + 1
  print("PASS " .. name)
end

local function assert_mapping(lhs, bufnr, expected_desc, expected_rhs)
  local mapping = find_map(lhs, bufnr)

  assert(mapping, "Missing mapping: " .. lhs)

  if expected_desc then
    assert(mapping.desc == expected_desc, ("Unexpected description for %s: %s"):format(lhs, tostring(mapping.desc)))
  end

  if expected_rhs then
    assert(mapping.rhs == expected_rhs, ("Unexpected RHS for %s: %s"):format(lhs, tostring(mapping.rhs)))
  end

  return mapping
end

local c_buf = vim.api.nvim_create_buf(false, true)
local rust_buf = vim.api.nvim_create_buf(false, true)

keymaps.c_cpp(c_buf)
keymaps.rust(rust_buf)

check("C/C++ build mapping is buffer-local", function()
  assert_mapping("<leader>cb", c_buf, "C/C++: Build project", "<Cmd>CMakeBuild<CR>")
end)

check("C/C++ run mapping is buffer-local", function()
  assert_mapping("<leader>cr", c_buf, "C/C++: Run executable", "<Cmd>CMakeRun<CR>")
end)

check("C/C++ source/header mapping is buffer-local", function()
  local mapping = find_map("<leader>ch", c_buf)

  assert(mapping, "Missing source/header mapping")
  assert(mapping.desc == "C/C++: Switch source/header")
  assert(type(mapping.callback) == "function")
end)

check("C/C++ mappings are not global", function()
  for _, lhs in ipairs({
    "<leader>cb",
    "<leader>cr",
    "<leader>ch",
  }) do
    assert(not find_map(lhs), "Unexpected global mapping: " .. lhs)
  end
end)

check("Rust mappings remain buffer-local", function()
  for _, lhs in ipairs({
    "<leader>cr",
    "<leader>cb",
    "<leader>ct",
    "<leader>cc",
  }) do
    local mapping = find_map(lhs, rust_buf)

    assert(mapping, "Missing Rust mapping: " .. lhs)
    assert(mapping.desc and mapping.desc:match("^Rust:"), "Unexpected mapping description for " .. lhs)
  end
end)

check("C/C++ and Rust mappings remain isolated", function()
  -- Shared key combinations must resolve to their language-specific
  -- implementations in each buffer.
  assert_mapping("<leader>cb", c_buf, "C/C++: Build project", "<Cmd>CMakeBuild<CR>")

  assert_mapping("<leader>cr", c_buf, "C/C++: Run executable", "<Cmd>CMakeRun<CR>")

  -- Rust-only mappings must not exist in the C/C++ buffer.
  for _, lhs in ipairs({
    "<leader>ct",
    "<leader>cc",
  }) do
    assert(not find_map(lhs, c_buf), "Unexpected Rust-only mapping in C/C++ buffer: " .. lhs)
  end

  -- The C/C++-only source/header mapping must not exist in Rust.
  assert(not find_map("<leader>ch", rust_buf), "Unexpected C/C++ mapping in Rust buffer: <leader>ch")

  -- Shared combinations must retain Rust descriptions in the Rust buffer.
  for _, lhs in ipairs({
    "<leader>cr",
    "<leader>cb",
  }) do
    local mapping = find_map(lhs, rust_buf)

    assert(mapping, "Missing Rust mapping: " .. lhs)
    assert(mapping.desc and mapping.desc:match("^Rust:"), "C/C++ mapping leaked into Rust buffer: " .. lhs)
  end
end)

check("Existing global Format mapping remains available", function()
  assert(find_map("<leader>cf"), "Global Format mapping is missing")
end)

vim.api.nvim_buf_delete(c_buf, { force = true })
vim.api.nvim_buf_delete(rust_buf, { force = true })

print(("%d C/C++ keymap checks passed"):format(passed))
