-- Stage 13: C language pack.
-- C owns its formatter and Tree-sitter parser metadata.
-- The shared clangd integration owns LSP configuration and activation.

local M = {
  formatters = {
    c = { "clang_format" },
  },

  parser_by_filetype = {
    c = "c",
  },
}

function M.setup()
  require("lsp.servers.clangd").setup()
end

return M
