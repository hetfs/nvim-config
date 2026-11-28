local root = vim.fn.tempname()
local source_dir = vim.fs.joinpath(root, "src")

vim.fn.mkdir(source_dir, "p")

vim.fn.writefile({
  "[package]",
  'name = "rust_lsp_test"',
  'version = "0.1.0"',
  'edition = "2024"',
}, vim.fs.joinpath(root, "Cargo.toml"))

local source = vim.fs.joinpath(source_dir, "main.rs")

vim.fn.writefile({
  "fn main() {",
  '    println!("Hello, Rust!");',
  "}",
}, source)

vim.cmd.edit(vim.fn.fnameescape(source))

local buf = vim.api.nvim_get_current_buf()

local attached = vim.wait(30000, function()
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = buf })) do
    if client.name == "rust_analyzer" then
      return true
    end
  end

  return false
end, 200)

assert(attached, "rust-analyzer did not attach within 30 seconds")

local rust_client

for _, client in ipairs(vim.lsp.get_clients({ bufnr = buf })) do
  if client.name == "rust_analyzer" then
    rust_client = client
    break
  end
end

assert(rust_client, "rust-analyzer client was not found")

print("LSP client:", rust_client.name)
print("Root directory:", rust_client.config.root_dir)

local actual_root = vim.fs.normalize(rust_client.config.root_dir or ""):lower()
local expected_root = vim.fs.normalize(root):lower()

assert(
  actual_root == expected_root,
  ("Expected root %s, got %s"):format(expected_root, actual_root)
)

local formatting_disabled = vim.wait(5000, function()
  return rust_client.server_capabilities.documentFormattingProvider == false
    and rust_client.server_capabilities.documentRangeFormattingProvider == false
end, 100)

print(
  "Document formatting:",
  rust_client.server_capabilities.documentFormattingProvider
)

print(
  "Range formatting:",
  rust_client.server_capabilities.documentRangeFormattingProvider
)

assert(
  formatting_disabled,
  "rust-analyzer document and range formatting should both be disabled"
)

print("PASS: rust-analyzer attached, resolved the Cargo root, and disabled LSP formatting")
