-- Stage 13: HTML language pack.
-- HTML owns its language server, formatter metadata, and Tree-sitter parser.
-- Shared LSP and formatting infrastructure remains centralized.

local M = {
  formatters = {
    html = { "prettier" },
  },

  filetypes = {
    html = { "html" },
  },

  parsers = {
    "html",
  },

  parser_by_filetype = {
    html = "html",
  },

  servers = {
    "html",
  },

  executables = {
    html = "vscode-html-language-server",
  },
}

local function enable(server, config)
  local executable = assert(M.executables[server], string.format("No executable configured for HTML server '%s'", server))

  -- Do not enable a server whose executable is unavailable.
  if vim.fn.executable(executable) ~= 1 then
    return
  end

  -- Extend the server definition provided by nvim-lspconfig.
  if config then
    vim.lsp.config(server, config)
  end

  -- Use Neovim's native LSP activation API.
  vim.lsp.enable(server)
end

function M.setup()
  enable("html", {
    settings = {
      html = {
        -- Prettier owns HTML formatting through Conform.
        format = {
          enable = false,
        },
      },
    },
  })
end

return M
