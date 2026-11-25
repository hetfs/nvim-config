-- Stage 24: Statusline.
-- Use Catppuccin, mini.icons, and built-in Lualine components.

vim.pack.add({
  {
    src = "https://github.com/nvim-lualine/lualine.nvim",
    name = "lualine.nvim",
  },
})

require("lualine").setup({
  options = {
    icons_enabled = true,
    theme = "catppuccin-nvim",

    component_separators = {
      left = "",
      right = "",
    },

    section_separators = {
      left = "",
      right = "",
    },

    globalstatus = false,
    always_divide_middle = true,

    disabled_filetypes = {
      statusline = {},
      winbar = {},
    },

    refresh = {
      statusline = 250,
      tabline = 500,
      winbar = 500,
    },
  },

  sections = {
    lualine_a = {
      "mode",
    },

    lualine_b = {
      "branch",
      "diff",
      {
        "diagnostics",
        sources = { "nvim_diagnostic" },
        sections = { "error", "warn", "info", "hint" },
        symbols = {
          error = "E:",
          warn = "W:",
          info = "I:",
          hint = "H:",
        },
      },
    },

    lualine_c = {
      {
        "filename",
        path = 1,
        file_status = true,
        newfile_status = true,
      },
    },

    lualine_x = {
      "encoding",
      "fileformat",
      "filetype",
    },

    lualine_y = {
      "progress",
    },

    lualine_z = {
      "location",
    },
  },

  inactive_sections = {
    lualine_a = {},
    lualine_b = {},

    lualine_c = {
      {
        "filename",
        path = 1,
        file_status = true,
      },
    },

    lualine_x = {
      "location",
    },

    lualine_y = {},
    lualine_z = {},
  },

  tabline = {},
  winbar = {},
  inactive_winbar = {},

  extensions = {},
})
