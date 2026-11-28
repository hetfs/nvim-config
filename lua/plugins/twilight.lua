-- Stage 28: Twilight.
-- Dim inactive portions of the current buffer.
--
-- Dependencies:
--   - Neovim >= 0.5
--   - Tree-sitter (optional)
--
-- Integration:
--   - zen-mode.nvim

vim.pack.add({
  {
    src = "https://github.com/folke/twilight.nvim",
    name = "twilight.nvim",
  },
})

require("twilight").setup({
  -- Dimming intensity.
  dimming = {
    alpha = 0.25,

    -- Use the current colorscheme's Normal foreground.
    color = {
      "Normal",
      "#ffffff",
    },

    term_bg = "#000000",

    -- Do not dim other windows.
    inactive = false,
  },

  -- Number of surrounding lines to keep visible.
  context = 10,

  -- Use line-based context detection.
  -- Avoids nil-parser errors on unsupported filetypes.
  treesitter = false,

  -- Retained for when Tree-sitter integration is enabled.
  expand = {
    "function",
    "method",
    "table",
    "if_statement",
  },

  -- Filetypes excluded from dimming.
  exclude = {
    "dashboard",
    "help",
    "lazy",
    "mason",
    "terminal",
    "snacks_dashboard",
    "snacks_picker_input",
  },
})

-- ============================================================
-- Keymaps
-- ============================================================

vim.keymap.set("n", "<leader>zt", "<cmd>Twilight<cr>", {
  desc = "Toggle Twilight",
})

vim.keymap.set("n", "<leader>ze", "<cmd>TwilightEnable<cr>", {
  desc = "Enable Twilight",
})

vim.keymap.set("n", "<leader>zd", "<cmd>TwilightDisable<cr>", {
  desc = "Disable Twilight",
})

