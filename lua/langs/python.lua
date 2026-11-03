-- Stage 13: Python language pack.
-- ty provides Python language intelligence and type analysis.
-- Ruff provides native LSP lint diagnostics and CLI linting.
-- Ruff formatting is handled separately through Conform.
-- Tree-sitter parser ownership is declared by filetype.

local M = {
  formatters = {
    python = { "ruff_format" },
  },

  parser_by_filetype = {
    python = "python",
  },
}

function M.setup()
  -- Use the server definitions supplied by nvim-lspconfig.
  -- Neovim's native LSP API owns configuration and activation.
  vim.lsp.enable("ty")
  vim.lsp.enable("ruff")
end

return M
