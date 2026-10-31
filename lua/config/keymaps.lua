-- Native Neovim keymaps.
-- Keep mappings centralized and describe them for discoverability.
-- Add workflow mappings only after their implementation and validation.

local M = {}
local map = vim.keymap.set

-- ============================================================
-- Window Navigation
-- ============================================================

map("n", "<C-h>", "<C-w><C-h>", {
  desc = "Focus left window",
})
map("n", "<C-j>", "<C-w><C-j>", {
  desc = "Focus lower window",
})
map("n", "<C-k>", "<C-w><C-k>", {
  desc = "Focus upper window",
})
map("n", "<C-l>", "<C-w><C-l>", {
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
-- Buffer and Tab Navigation
-- ============================================================

map("n", "<S-q>", "<cmd>bdelete<CR>", {
  desc = "Close buffer",
})

map("n", "<leader>1", "1gt", {
  desc = "Go to tab 1",
})
map("n", "<leader>2", "2gt", {
  desc = "Go to tab 2",
})
map("n", "<leader>3", "3gt", {
  desc = "Go to tab 3",
})
map("n", "<leader>4", "4gt", {
  desc = "Go to tab 4",
})
map("n", "<leader>5", "5gt", {
  desc = "Go to tab 5",
})

map("n", "<leader>t", "<cmd>tabnew<CR>", {
  desc = "New tab",
})
map("n", "<A-q>", "<cmd>tabclose<CR>", {
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

-- Formatting

map("n", "<leader>cf", "<cmd>Format<CR>", {
  desc = "Format buffer",
})

-- Start a buffer-wide substitution using the previous search pattern.
-- Review the replacement before confirming the command.
map("n", "S", ":%s/<C-r>//g<Left><Left>", {
  desc = "Replace previous search in buffer",
})

-- ============================================================
-- Terminal
-- ============================================================

map("t", "<Esc><Esc>", "<C-\\><C-n>", {
  desc = "Exit terminal mode",
})

-- ============================================================
-- LSP
-- ============================================================

-- Register buffer-local mappings when an LSP client attaches.
function M.lsp(bufnr)
  local opts = {
    buffer = bufnr,
  }

  map(
    "n",
    "gd",
    vim.lsp.buf.definition,
    vim.tbl_extend("force", opts, {
      desc = "LSP: Go to definition",
    })
  )

  map(
    "n",
    "gD",
    vim.lsp.buf.declaration,
    vim.tbl_extend("force", opts, {
      desc = "LSP: Go to declaration",
    })
  )
end

-- Git hunk mappings are installed for buffers attached by gitsigns.
function M.gitsigns(bufnr)
  local gs = require("gitsigns")

  local opts = { buffer = bufnr }

  opts.desc = "Git: Stage hunk"
  map("n", "<leader>ghs", gs.stage_hunk, opts)

  opts.desc = "Git: Reset hunk"
  map("n", "<leader>ghr", gs.reset_hunk, opts)

  opts.desc = "Git: Preview hunk"
  map("n", "<leader>ghp", gs.preview_hunk, opts)

  opts.desc = "Git: Blame line"
  map("n", "<leader>ghb", gs.blame_line, opts)

  opts.desc = "Git: Diff buffer"
  map("n", "<leader>ghd", gs.diffthis, opts)
end

-- ============================================================
-- Sessions
-- ============================================================

local sessions = require("mini.sessions")

map("n", "<leader>qs", function()
  sessions.select("read")
end, {
  desc = "Session: Restore",
})

map("n", "<leader>qw", function()
  sessions.select("write")
end, {
  desc = "Session: Save",
})

map("n", "<leader>qd", function()
  sessions.select("delete")
end, {
  desc = "Session: Delete",
})

-- jq: Run a filter against the current buffer.
vim.keymap.set("n", "<leader>jq", function()
  require("langs.data").run_prompt()
end, {
  desc = "Run jq filter",
})

return M
