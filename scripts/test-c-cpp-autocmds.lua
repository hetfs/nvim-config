vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

local original_buf = vim.api.nvim_get_current_buf()

local passed = 0

-- Load the native autocommands.
require("config.autocmds")

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

local function create_filetype_buffer(filetype)
  local buf = vim.api.nvim_create_buf(false, true)

  vim.api.nvim_set_current_buf(buf)
  vim.bo[buf].filetype = filetype

  return buf
end

local c_buf = create_filetype_buffer("c")
local cpp_buf = create_filetype_buffer("cpp")
local rust_buf = create_filetype_buffer("rust")
local text_buf = create_filetype_buffer("text")

check("C FileType registers C/C++ mappings", function()
  assert_mapping("<leader>cb", c_buf, "C/C++: Build project", "<Cmd>CMakeBuild<CR>")

  assert_mapping("<leader>cr", c_buf, "C/C++: Run executable", "<Cmd>CMakeRun<CR>")

  local mapping = assert_mapping("<leader>ch", c_buf, "C/C++: Switch source/header")

  assert(type(mapping.callback) == "function")
end)

check("C++ FileType registers C/C++ mappings", function()
  assert_mapping("<leader>cb", cpp_buf, "C/C++: Build project", "<Cmd>CMakeBuild<CR>")

  assert_mapping("<leader>cr", cpp_buf, "C/C++: Run executable", "<Cmd>CMakeRun<CR>")

  local mapping = assert_mapping("<leader>ch", cpp_buf, "C/C++: Switch source/header")

  assert(type(mapping.callback) == "function")
end)

check("Rust FileType preserves Rust mappings", function()
  for _, lhs in ipairs({
    "<leader>cr",
    "<leader>cb",
    "<leader>ct",
    "<leader>cc",
  }) do
    local mapping = find_map(lhs, rust_buf)

    assert(mapping, "Missing Rust mapping: " .. lhs)
    assert(mapping.desc and mapping.desc:match("^Rust:"), "Unexpected Rust mapping description for " .. lhs)
  end
end)

check("Language mappings remain buffer-local", function()
  for _, lhs in ipairs({
    "<leader>cb",
    "<leader>cr",
    "<leader>ch",
  }) do
    assert(not find_map(lhs), "Unexpected global C/C++ mapping: " .. lhs)
  end

  for _, buf in ipairs({
    c_buf,
    cpp_buf,
    rust_buf,
    text_buf,
  }) do
    assert(vim.api.nvim_buf_is_valid(buf), "Expected test buffer to remain valid")
  end
end)

check("C/C++ and Rust FileType mappings remain isolated", function()
  for _, buf in ipairs({
    c_buf,
    cpp_buf,
  }) do
    for _, lhs in ipairs({
      "<leader>ct",
      "<leader>cc",
    }) do
      assert(not find_map(lhs, buf), "Unexpected Rust-only mapping in C/C++ buffer: " .. lhs)
    end
  end

  assert(not find_map("<leader>ch", rust_buf), "Unexpected C/C++ source/header mapping in Rust buffer")
end)

check("Unrelated FileType does not receive C/C++ mappings", function()
  for _, lhs in ipairs({
    "<leader>cb",
    "<leader>cr",
    "<leader>ch",
  }) do
    assert(not find_map(lhs, text_buf), "Unexpected C/C++ mapping in text buffer: " .. lhs)
  end
end)

check("Existing global Format mapping remains available", function()
  assert(find_map("<leader>cf"), "Global Format mapping is missing")
end)

-- Restore the original buffer before deleting test buffers.
vim.api.nvim_set_current_buf(original_buf)

for _, buf in ipairs({
  c_buf,
  cpp_buf,
  rust_buf,
  text_buf,
}) do
  if vim.api.nvim_buf_is_valid(buf) then
    vim.api.nvim_buf_delete(buf, {
      force = true,
    })
  end
end

print(("%d C/C++ autocmd checks passed"):format(passed))
