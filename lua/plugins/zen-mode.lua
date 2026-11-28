-- Stage 26: Distraction-free editing.
-- Preserve the existing window layout when entering and leaving Zen Mode.
--
-- Plugin:
--   - zen-mode.nvim
--
-- Features:
--   - Centered floating editing window.
--   - Responsive width, up to 120 columns.
--   - Full editor height.
--   - Dimmed backdrop.
--   - Hide distracting window options.
--   - Restore original editor options when Zen Mode closes.
--
-- Keymaps:
--   - <leader>z: Toggle Zen Mode.

vim.pack.add({
  {
    src = "https://github.com/folke/zen-mode.nvim",
    name = "zen-mode.nvim",
  },
})

local zen = require("zen-mode")

zen.setup({
  -- ==========================================================
  -- Floating window
  -- ==========================================================

  window = {
    backdrop = 0.95,

    width = function()
      return math.min(120, math.floor(vim.o.columns * 0.85))
    end,

    height = 1,

    options = {
      signcolumn = "no",
      number = false,
      relativenumber = false,
      cursorline = false,
      cursorcolumn = false,
      foldcolumn = "0",
      list = false,
    },
  },

  -- ==========================================================
  -- Plugin integrations
  -- ==========================================================

  plugins = {
    options = {
      enabled = true,
      ruler = false,
      showcmd = false,
      laststatus = 0,
    },

    twilight = {
      enabled = true,
    },

    gitsigns = {
      enabled = false,
    },

    todo = {
      enabled = false,
    },

    diagnostics = {
      enabled = false,
    },

    tmux = {
      enabled = false,
    },

    kitty = {
      enabled = false,
    },

    alacritty = {
      enabled = false,
    },

    wezterm = {
      enabled = false,
    },

    neovide = {
      enabled = false,
    },
  },
})

-- ============================================================
-- Keymaps
-- ============================================================

vim.keymap.set("n", "<leader>z", function()
  zen.toggle()
end, {
  desc = "Toggle Zen Mode",
})

