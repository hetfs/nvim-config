-- Stage 13: TypeScript language pack.
-- TypeScript owns its formatter and Tree-sitter parser metadata.
-- The shared vtsls integration owns server configuration and activation.

local M = {
  formatters = {
    typescript = { "prettier" },
    typescriptreact = { "prettier" },
  },

  parser_by_filetype = {
    typescript = "typescript",
    typescriptreact = "tsx",
  },
}

function M.setup()
  require("lsp.servers.vtsls").setup()
end

return M
