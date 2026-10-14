-- Native keymaps.
-- Leader keys are set in init.lua before this module loads.

local map = vim.keymap.set

-- Saving and basic editing.
map("n", "<C-s>", "<cmd>write<cr>", {
  desc = "Save file",
  silent = true,
})

map({ "i", "x" }, "<C-s>", "<Esc><cmd>write<cr>", {
  desc = "Save file",
  silent = true,
})

map("n", "<Esc>", "<cmd>nohlsearch<cr>", {
  desc = "Clear search highlights",
  silent = true,
})

-- Window navigation.
map("n", "<C-h>", "<C-w>h", {
  desc = "Focus left window",
  silent = true,
})

map("n", "<C-j>", "<C-w>j", {
  desc = "Focus lower window",
  silent = true,
})

map("n", "<C-k>", "<C-w>k", {
  desc = "Focus upper window",
  silent = true,
})

map("n", "<C-l>", "<C-w>l", {
  desc = "Focus right window",
  silent = true,
})

-- Window management.
map("n", "<leader>sv", "<cmd>vsplit<cr>", {
  desc = "Split window vertically",
  silent = true,
})

map("n", "<leader>sh", "<cmd>split<cr>", {
  desc = "Split window horizontally",
  silent = true,
})

map("n", "<leader>se", "<C-w>=", {
  desc = "Equalize window sizes",
  silent = true,
})

map("n", "<leader>sx", "<cmd>close<cr>", {
  desc = "Close current window",
  silent = true,
})

-- Basic window resizing.
map("n", "<C-Up>", "<cmd>resize +2<cr>", {
  desc = "Increase window height",
  silent = true,
})

map("n", "<C-Down>", "<cmd>resize -2<cr>", {
  desc = "Decrease window height",
  silent = true,
})

map("n", "<C-Left>", "<cmd>vertical resize -2<cr>", {
  desc = "Decrease window width",
  silent = true,
})

map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", {
  desc = "Increase window width",
  silent = true,
})

-- Keep the cursor centered when moving through search results.
map("n", "n", "nzzzv", {
  desc = "Next search result",
  silent = true,
})

map("n", "N", "Nzzzv", {
  desc = "Previous search result",
  silent = true,
})
