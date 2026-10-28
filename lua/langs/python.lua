-- Stage 13: Python language pack.
-- ty is an external language server; Neovim owns LSP activation.
-- Ruff is an external formatter and CLI linter.
-- Editor linting remains subject to the Stage 11 admission review.

local M = {
  formatters = {
    python = { "ruff_format" },
  },
}

function M.setup()
  -- Use the server definition supplied by nvim-lspconfig.
  -- Neovim's native LSP API owns configuration and activation.
  vim.lsp.enable("ty")
end

return M
