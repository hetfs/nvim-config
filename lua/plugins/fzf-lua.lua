-- Stage 07: fzf-lua navigation.
-- Keep this configuration and its keymaps independent from Snacks.

vim.pack.add({
  {
    src = "https://github.com/ibhagwan/fzf-lua",
    name = "fzf-lua",
  },
})

require("fzf-lua").setup({})

-- ============================================================
-- fzf-lua Navigation
-- ============================================================

vim.keymap.set("n", "<leader>pf", function()
  require("fzf-lua").files()
end, {
  desc = "Fzf: Find files",
})

vim.keymap.set("n", "<leader>pg", function()
  require("fzf-lua").live_grep()
end, {
  desc = "Fzf: Search file contents",
})

vim.keymap.set("n", "<leader>pb", function()
  require("fzf-lua").buffers()
end, {
  desc = "Fzf: Find buffers",
})

vim.keymap.set("n", "<leader>pr", function()
  require("fzf-lua").resume()
end, {
  desc = "Fzf: Resume picker",
})
