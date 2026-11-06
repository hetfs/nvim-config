-- Stage 13: CSS language pack.
-- CSS owns its language server, formatter metadata, and Tree-sitter parser.
-- Shared LSP and formatting infrastructure remains centralized.

local M = {
  formatters = {
    css = { "prettier" },
  },

  parser_by_filetype = {
    css = "css",
  },

  servers = {
    cssls = true,
  },

  executables = {
    cssls = "vscode-css-language-server",
  },
}

local function enable(server, config)
  local executable = assert(M.executables[server], string.format("No executable configured for CSS server '%s'", server))

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
  enable("cssls", {
    settings = {
      css = {
        validate = true,
      },
      scss = {
        validate = true,
      },
      less = {
        validate = true,
      },
    },
  })
end

return M
