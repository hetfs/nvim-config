
-- Native Neovim keymaps.
-- Keep mappings centralized and describe them for discoverability.
-- Add workflow mappings only after their implementation and validation.

local M = {}
local map = vim.keymap.set

-- ============================================================
-- Window Navigation
-- ============================================================

map("n", "<C-h>", "<C-w>h", {
  desc = "Focus left window",
})

map("n", "<C-j>", "<C-w>j", {
  desc = "Focus lower window",
})

map("n", "<C-k>", "<C-w>k", {
  desc = "Focus upper window",
})

map("n", "<C-l>", "<C-w>l", {
  desc = "Focus right window",
})

-- ============================================================
-- Window Resizing
-- ============================================================

map("n", "<C-Up>", "<cmd>resize -2<CR>", {
  desc = "Decrease window height",
})

map("n", "<C-Down>", "<cmd>resize +2<CR>", {
  desc = "Increase window height",
})

map("n", "<C-Left>", "<cmd>vertical resize -2<CR>", {
  desc = "Decrease window width",
})

map("n", "<C-Right>", "<cmd>vertical resize +2<CR>", {
  desc = "Increase window width",
})

-- ============================================================
-- File Operations
-- ============================================================

map({ "n", "i", "v" }, "<C-s>", "<cmd>write<CR>", {
  desc = "Save file",
})

-- ============================================================
-- Window Management
-- ============================================================

map("n", "<leader>sv", "<cmd>vsplit<CR>", {
  desc = "Split window vertically",
})

map("n", "<leader>sh", "<cmd>split<CR>", {
  desc = "Split window horizontally",
})

map("n", "<leader>se", "<C-w>=", {
  desc = "Equalize window sizes",
})

map("n", "<leader>sx", "<cmd>close<CR>", {
  desc = "Close current window",
})

-- ============================================================
-- Terminal
-- ============================================================

-- Open a terminal in a bottom split.
map("n", "<leader>tt", "<cmd>botright 12split | terminal<CR>", {
  desc = "Open terminal",
})

map("n", "<leader>tv", "<cmd>vertical split | terminal<CR>", {
  desc = "Open vertical terminal",
})

map("n", "<leader>th", "<cmd>split | terminal<CR>", {
  desc = "Open horizontal terminal",
})

map("t", "<Esc>", "<C-\\><C-n>", {
  desc = "Exit terminal mode",
})

-- Navigate between windows directly from terminal mode.
map("t", "<A-h>", "<C-\\><C-n><C-w>h", {
  desc = "Focus left window",
})

map("t", "<A-j>", "<C-\\><C-n><C-w>j", {
  desc = "Focus lower window",
})

map("t", "<A-k>", "<C-\\><C-n><C-w>k", {
  desc = "Focus upper window",
})

map("t", "<A-l>", "<C-\\><C-n><C-w>l", {
  desc = "Focus right window",
})

map("n", "<leader>tq", "<cmd>close<CR>", {
  desc = "Close terminal window",
})

-- ============================================================
-- Buffer Navigation
-- ============================================================

map("n", "<leader>bd", "<cmd>bdelete<CR>", {
  desc = "Close buffer",
})

map("n", "<S-h>", "<cmd>bprevious<CR>", {
  desc = "Previous buffer",
})

map("n", "<S-l>", "<cmd>bnext<CR>", {
  desc = "Next buffer",
})

-- ============================================================
-- Tab Navigation
-- ============================================================

for i = 1, 5 do
  map("n", "<leader>" .. i, i .. "gt", {
    desc = "Go to tab " .. i,
  })
end

map("n", "<leader>tn", "<cmd>tabnew<CR>", {
  desc = "New tab",
})

map("n", "<leader>tc", "<cmd>tabclose<CR>", {
  desc = "Close tab",
})

-- ============================================================
-- Search
-- ============================================================

map("n", "<Esc>", "<cmd>nohlsearch<CR>", {
  desc = "Clear search highlights",
})

map("n", "<leader>nh", "<cmd>nohlsearch<CR>", {
  desc = "Clear search highlights",
})

-- ============================================================
-- Navigation Extras
-- ============================================================

-- Navigate by display line when wrapping is enabled.
-- Preserve normal line-count behavior.
map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", {
  expr = true,
  desc = "Move down (wrapped-line aware)",
})

map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", {
  expr = true,
  desc = "Move up (wrapped-line aware)",
})

-- Keep the cursor centered during scrolling and searching.
map("n", "<C-d>", "<C-d>zz", {
  desc = "Scroll down (centered)",
})

map("n", "<C-u>", "<C-u>zz", {
  desc = "Scroll up (centered)",
})

map("n", "n", "nzzzv", {
  desc = "Next match (centered)",
})

map("n", "N", "Nzzzv", {
  desc = "Previous match (centered)",
})

-- ============================================================
-- Editing
-- ============================================================

map("i", "jk", "<Esc>", {
  desc = "Exit insert mode",
})

map("x", "p", '"_dP', {
  desc = "Paste without overwriting clipboard",
})

map("x", "<", "<gv", {
  desc = "Dedent and stay in visual mode",
})

map("x", ">", ">gv", {
  desc = "Indent and stay in visual mode",
})

map("n", "<leader>e", "$", {
  desc = "Jump to end of line",
})

-- ============================================================
-- Formatting
-- ============================================================

-- Formatting remains manual.
map("n", "<leader>cf", "<cmd>Format<CR>", {
  desc = "Format buffer",
})

-- ============================================================
-- Search and Replace
-- ============================================================

-- Reuse the previous search pattern.
-- Review the replacement before executing.
map("n", "<leader>rs", ":%s/<C-r>//g<Left><Left>", {
  desc = "Replace previous search in buffer",
})

-- ============================================================
-- Line Movement
-- ============================================================

map("n", "<A-j>", "<cmd>m .+1<CR>==", {
  desc = "Move line down",
})

map("n", "<A-k>", "<cmd>m .-2<CR>==", {
  desc = "Move line up",
})

map("x", "<A-j>", ":m '>+1<CR>gv=gv", {
  desc = "Move selection down",
})

map("x", "<A-k>", ":m '<-2<CR>gv=gv", {
  desc = "Move selection up",
})

-- ============================================================
-- Diagnostics
-- ============================================================

map("n", "<leader>cd", vim.diagnostic.open_float, {
  desc = "Show line diagnostics",
})

map("n", "<leader>cq", function()
  vim.diagnostic.setqflist()
end, {
  desc = "Diagnostics to quickfix",
})

-- ============================================================
-- LSP
-- ============================================================

-- Register buffer-local mappings when an LSP client attaches.
function M.lsp(bufnr)
  local function lmap(mode, lhs, rhs, desc)
    map(mode, lhs, rhs, {
      buffer = bufnr,
      desc = "LSP: " .. desc,
    })
  end

  lmap("n", "gd", vim.lsp.buf.definition, "Go to definition")

  lmap("n", "gD", vim.lsp.buf.declaration, "Go to declaration")

  lmap(
    { "n", "i" },
    "<leader>ck",
    vim.lsp.buf.signature_help,
    "Signature help"
  )
end

-- ============================================================
-- Git
-- ============================================================

-- Register buffer-local mappings when Gitsigns attaches.
function M.gitsigns(bufnr)
  local gs = require("gitsigns")

  local function git_map(lhs, callback, description)
    map("n", lhs, callback, {
      buffer = bufnr,
      desc = "Git: " .. description,
    })
  end

  git_map("<leader>ghs", gs.stage_hunk, "Stage hunk")
  git_map("<leader>ghr", gs.reset_hunk, "Reset hunk")
  git_map("<leader>ghp", gs.preview_hunk, "Preview hunk")
  git_map("<leader>ghb", gs.blame_line, "Blame line")
  git_map("<leader>ghd", gs.diffthis, "Diff buffer")
end

-- ============================================================
-- Sessions
-- ============================================================

-- Load Mini Sessions only when a session command is invoked.
map("n", "<leader>qs", function()
  require("mini.sessions").select("read")
end, {
  desc = "Session: Restore",
})

map("n", "<leader>qw", function()
  require("mini.sessions").select("write")
end, {
  desc = "Session: Save",
})

map("n", "<leader>qd", function()
  require("mini.sessions").select("delete")
end, {
  desc = "Session: Delete",
})

-- ============================================================
-- Data Tools
-- ============================================================

map("n", "<leader>jq", function()
  require("langs.data").run_prompt()
end, {
  desc = "Run jq filter",
})

-- ============================================================
-- Central LSP operations.
-- ============================================================

map("n", "<leader>rn", vim.lsp.buf.rename, {
  desc = "LSP: Rename symbol",
})

map("n", "<leader>ca", vim.lsp.buf.code_action, {
  desc = "LSP: Code actions",
})

-- ============================================================
-- Shell
-- ============================================================

vim.keymap.set("n", "<leader>cw", "<cmd>ShellcheckWiki<CR>", {
  desc = "Open ShellCheck wiki",

})return M
