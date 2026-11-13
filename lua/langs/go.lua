-- Stage 13: Go language pack.
-- Go owns its formatter and Tree-sitter parser metadata.
-- The upstream nvim-lspconfig definition supplies gopls.

local M = {
  formatters = {
    go = { "gofmt" },
  },

  parser_by_filetype = {
    go = "go",
    gomod = "gomod",
    gowork = "gowork",
    gotmpl = "gotmpl",
  },
}

function M.setup()
  vim.lsp.enable("gopls")
end

return M
