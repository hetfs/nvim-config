-- Stage 13: JavaScript language pack.
-- JavaScript owns its formatter and Tree-sitter parser metadata.
-- The shared vtsls integration owns server configuration and activation.

local M = {
  formatters = {
    javascript = { "prettier" },
  },

  parser_by_filetype = {
    javascript = "javascript",
  },
}

function M.setup()
  require("lsp.servers.vtsls").setup()
end

return M
