-- Stage 13: C++ language pack.
-- C++ owns its formatter and Tree-sitter parser metadata.
-- The shared clangd integration owns LSP configuration and activation.

local M = {
  formatters = {
    cpp = { "clang_format" },
  },

  parser_by_filetype = {
    cpp = "cpp",
  },
}

function M.setup()
  require("lsp.servers.clangd").setup()
end

return M
