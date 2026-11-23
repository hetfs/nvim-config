-- Stage 27: Enhanced command-line and message presentation.
-- Preserve native completion, notifications, input, and selection.

vim.pack.add({
  {
    src = "https://github.com/MunifTanjim/nui.nvim",
    name = "nui.nvim",
  },
  {
    src = "https://github.com/folke/noice.nvim",
    name = "noice.nvim",
  },
})

-- Activate the required UI dependency before loading Noice.
vim.cmd.packadd("nui.nvim")

require("noice").setup({
  cmdline = {
    enabled = true,
    view = "cmdline_popup",

    format = {
      cmdline = {
        pattern = "^:",
        icon = ">",
        lang = "vim",
      },

      search_down = {
        kind = "search",
        pattern = "^/",
        icon = "/",
        lang = "regex",
      },

      search_up = {
        kind = "search",
        pattern = "^%?",
        icon = "?",
        lang = "regex",
      },

      filter = {
        pattern = "^:%s*!",
        icon = "$",
        lang = "bash",
      },

      lua = {
        pattern = {
          "^:%s*lua%s+",
          "^:%s*lua%s*=%s*",
          "^:%s*=%s*",
        },
        icon = "lua",
        lang = "lua",
      },

      help = {
        pattern = "^:%s*he?l?p?%s+",
        icon = "?",
      },

      input = {
        view = "cmdline_input",
        icon = "=",
      },
    },
  },

  messages = {
    enabled = true,
    view = "mini",
    view_error = "mini",
    view_warn = "mini",
    view_history = "messages",
    view_search = "virtualtext",
  },

  -- Keep Neovim's native completion popup.
  popupmenu = {
    enabled = false,
  },

  -- Keep Neovim's native vim.notify().
  notify = {
    enabled = false,
  },

  lsp = {
    progress = {
      enabled = true,
      view = "mini",
    },

    message = {
      enabled = true,
      view = "mini",
    },

    -- Preserve native LSP hover and signature-help presentation.
    hover = {
      enabled = false,
    },

    signature = {
      enabled = false,
    },

    -- Preserve native LSP markdown rendering.
    override = {
      ["vim.lsp.util.convert_input_to_markdown_lines"] = false,
      ["vim.lsp.util.stylize_markdown"] = false,
      ["cmp.entry.get_documentation"] = false,
    },
  },

  presets = {
    bottom_search = false,
    command_palette = false,
    long_message_to_split = true,
    inc_rename = false,
    lsp_doc_border = false,
  },
})
