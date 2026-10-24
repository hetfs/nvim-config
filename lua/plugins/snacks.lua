-- Stage 07: Snacks navigation.
-- Enable only Picker and Explorer; the dashboard is deferred to Stage 15.

vim.pack.add({
  {
    src = "https://github.com/folke/snacks.nvim",
    name = "snacks.nvim",
  },
})

require("snacks").setup({
  picker = {
    enabled = true,
  },
  explorer = {
    enabled = true,
    replace_netrw = true,
  },
})

-- ============================================================
-- Snacks Navigation
-- ============================================================

vim.keymap.set("n", "<leader>ff", function()
  require("snacks").picker.files()
end, {
  desc = "Find files",
})

vim.keymap.set("n", "<leader>fg", function()
  require("snacks").picker.grep()
end, {
  desc = "Search file contents",
})

vim.keymap.set("n", "<leader>fb", function()
  require("snacks").picker.buffers()
end, {
  desc = "Find buffers",
})

vim.keymap.set("n", "<leader>fe", function()
  require("snacks").explorer.open()
end, {
  desc = "Open file explorer",
})
