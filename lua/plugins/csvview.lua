-- CSV and TSV editing with virtual-text table rendering.
-- Keep activation manual; the plugin only changes presentation when enabled.

vim.pack.add({
  {
    src = "https://github.com/hat0uma/csvview.nvim",
    name = "csvview.nvim",
  },
})

---@module "csvview"
---@type CsvView.Options
require("csvview").setup({
  parser = {
    comments = { "#", "//" },
  },

  keymaps = {
    -- Field text objects.
    textobject_field_inner = {
      "if",
      mode = { "o", "x" },
    },
    textobject_field_outer = {
      "af",
      mode = { "o", "x" },
    },

    -- Horizontal navigation.
    jump_next_field_end = {
      "<Tab>",
      mode = { "n", "v" },
    },
    jump_prev_field_end = {
      "<S-Tab>",
      mode = { "n", "v" },
    },

    -- Vertical navigation.
    jump_next_row = {
      "<Enter>",
      mode = { "n", "v" },
    },
    jump_prev_row = {
      "<S-Enter>",
      mode = { "n", "v" },
    },
  },
})

-- ============================================================
-- CSVView Keymaps
-- ============================================================

local map = vim.keymap.set

map("n", "<leader>vv", "<Cmd>CsvViewToggle<CR>", {
  desc = "Toggle CSV view",
})

map("n", "<leader>ve", "<Cmd>CsvViewEnable<CR>", {
  desc = "Enable CSV view",
})

map("n", "<leader>vd", "<Cmd>CsvViewDisable<CR>", {
  desc = "Disable CSV view",
})

map("n", "<leader>vi", "<Cmd>CsvViewInfo<CR>", {
  desc = "Show CSV information",
})
