local buf = vim.api.nvim_create_buf(false, true)

vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
  "fn main() {",
  '    println!("Hello, Rust!");',
  "}",
})

vim.bo[buf].filetype = "rust"

-- Allow the automatic parser installation to complete.
local installed = vim.wait(300000, function()
  local files = vim.api.nvim_get_runtime_file("parser/rust.*", false)
  return #files > 0
end, 500)

print("Rust parser installation completed:", installed)

local files = vim.api.nvim_get_runtime_file("parser/rust.*", false)
print("Rust parser files:", vim.inspect(files))

assert(installed, "Rust parser was not installed within five minutes")

-- Verify that Neovim can load and use the installed parser.
local ok, parser = pcall(vim.treesitter.get_parser, buf, "rust")

print("Parser lookup successful:", ok)
print("Parser:", vim.inspect(parser))

assert(ok and parser, "Neovim could not load the Rust parser")

local parsed, trees = pcall(function()
  return parser:parse()
end)

print("Parse successful:", parsed)

assert(parsed, "Rust source parsing failed: " .. tostring(trees))

print("Syntax trees:", #trees)
print("PASS: Automatic Rust parser installation and parsing succeeded")

local highlighting, err = pcall(vim.treesitter.start, buf, "rust")

print("Tree-sitter highlighting started:", highlighting)

if not highlighting then
  error(err)
end

print("PASS: Rust Tree-sitter highlighting started")

local buf = vim.api.nvim_create_buf(false, true)

vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
  "fn main() {",
  '    println!("Hello, Rust!");',
  "}",
})

vim.api.nvim_set_current_buf(buf)

-- Trigger the existing Rust FileType autocmd.
vim.bo[buf].filetype = "rust"

-- Wait for automatic parser installation if necessary.
local ready = vim.wait(300000, function()
  local files = vim.api.nvim_get_runtime_file("parser/rust.*", false)
  return #files > 0
end, 500)

assert(ready, "Rust parser installation timed out")

-- Verify that the FileType autocmd started highlighting.
local started = vim.treesitter.highlighter.active[buf] ~= nil

print("Automatic highlighting started:", started)

assert(started, "Rust highlighting was not started automatically")

-- Verify that the buffer can be parsed.
local parser = vim.treesitter.get_parser(buf, "rust")
local trees = parser:parse()

print("Syntax trees:", #trees)
print("PASS: Rust FileType autocmd started Tree-sitter highlighting")

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

-- Open the Rust project file.
vim.cmd.edit(vim.fn.fnameescape(source))

local buf = vim.api.nvim_get_current_buf()

-- Wait for rust-analyzer to attach.
local attached = vim.wait(30000, function()
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = buf })) do
    if client.name == "rust_analyzer" then
      return true
    end
  end

  return false
end, 200)

assert(attached, "rust-analyzer did not attach within 30 seconds")

local clients = vim.lsp.get_clients({ bufnr = buf })

for _, client in ipairs(clients) do
  if client.name == "rust_analyzer" then
    print("LSP client:", client.name)
    print("Root directory:", client.config.root_dir)

    -- Allow the shared LspAttach and Rust-specific callbacks to run.
    vim.wait(5000, function()
      return client.server_capabilities.documentFormattingProvider == false
        and client.server_capabilities.documentRangeFormattingProvider == false
    end, 100)

    print(
      "Document formatting:",
      client.server_capabilities.documentFormattingProvider
    )

    print(
      "Range formatting:",
      client.server_capabilities.documentRangeFormattingProvider
    )

    assert(
      client.server_capabilities.documentFormattingProvider == false,
      "rust-analyzer document formatting should be disabled"
    )

    assert(
      client.server_capabilities.documentRangeFormattingProvider == false,
      "rust-analyzer range formatting should be disabled"
    )
  end
end

print("PASS: rust-analyzer attached and LSP formatting was disabled")
