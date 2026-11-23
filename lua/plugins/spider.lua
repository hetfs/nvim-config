-- Stage 17: Smarter word navigation.
-- Preserve native uppercase motions and Vim-compatible cw behavior.

vim.pack.add({
  {
    src = "https://github.com/chrisgrieser/nvim-spider",
    name = "nvim-spider",
  },
})

require("spider").setup({
  skipInsignificantPunctuation = true,
  subwordMovement = true,
  consistentOperatorPending = false,
  customPatterns = {},
})

-- Use Ex-command mappings to preserve dot-repeat behavior.
-- Spider supports Normal, Operator-pending, and Visual modes.

local modes = { "n", "o", "x" }

vim.keymap.set(modes, "w", "<cmd>lua require('spider').motion('w')<CR>", {
  desc = "Spider: Next word",
})

vim.keymap.set(modes, "e", "<cmd>lua require('spider').motion('e')<CR>", {
  desc = "Spider: End of word",
})

vim.keymap.set(modes, "b", "<cmd>lua require('spider').motion('b')<CR>", {
  desc = "Spider: Previous word",
})

vim.keymap.set(modes, "ge", "<cmd>lua require('spider').motion('ge')<CR>", {
  desc = "Spider: Previous word end",
})

-- Preserve Vim's familiar change-word behavior.
vim.keymap.set("n", "cw", "ce", {
  remap = true,
  desc = "Change to end of word",
})
