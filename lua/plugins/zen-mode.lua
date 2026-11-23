-- Stage 26: Distraction-free editing.
-- Preserve the existing window layout when entering and leaving Zen Mode.

vim.pack.add({
  {
    src = "https://github.com/folke/zen-mode.nvim",
    name = "zen-mode.nvim",
  },
})

require("zen-mode").setup({
  window = {
    backdrop = 0.95,
    width = 120,
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

  plugins = {
    options = {
      enabled = true,
      ruler = false,
      showcmd = false,
      laststatus = 0,
    },

    twilight = {
      enabled = false,
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
