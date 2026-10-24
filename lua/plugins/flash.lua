-- Stage 07: Flash navigation.
-- Keep Flash setup and plugin-specific keymaps together.

vim.pack.add({
  {
    src = "https://github.com/folke/flash.nvim",
    name = "flash.nvim",
  },
})

require("flash").setup({})

vim.keymap.set({ "n", "x", "o" }, "s", function()
  require("flash").jump()
end, { desc = "Flash: Jump" })

-- Use gs to preserve the existing Normal-mode S substitution mapping.
vim.keymap.set({ "n", "x", "o" }, "gs", function()
  require("flash").treesitter()
end, { desc = "Flash: Treesitter jump" })

vim.keymap.set("o", "r", function()
  require("flash").remote()
end, { desc = "Flash: Remote operation" })

vim.keymap.set({ "o", "x" }, "R", function()
  require("flash").treesitter_search()
end, { desc = "Flash: Treesitter search" })

vim.keymap.set("c", "<C-s>", function()
  require("flash").toggle()
end, { desc = "Flash: Toggle search labels" })
