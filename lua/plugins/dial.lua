-- Stage 07: dial.nvim increment and decrement.
-- Keep Dial configuration and plugin-specific keymaps together.

vim.pack.add({
  {
    src = "https://github.com/monaqa/dial.nvim",
    name = "dial.nvim",
  },
})

local dial = require("dial.map")

vim.keymap.set("n", "<C-a>", dial.inc_normal(), {
  desc = "Dial: Increment",
})

vim.keymap.set("n", "<C-x>", dial.dec_normal(), {
  desc = "Dial: Decrement",
})

vim.keymap.set("v", "<C-a>", dial.inc_visual(), {
  desc = "Dial: Increment selection",
})

vim.keymap.set("v", "<C-x>", dial.dec_visual(), {
  desc = "Dial: Decrement selection",
})
