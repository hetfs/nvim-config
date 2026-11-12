-- Stage 13: Markdown language pack.
--
-- Marksman is an external executable configured through the
-- shared native LSP integration.
--
-- Formatting and Tree-sitter metadata are declared
-- by this language pack.

local M = {
  formatters = {
    markdown = { "prettier" },
  },

  -- Map Markdown filetype to its primary Tree-sitter parser.
  parser_by_filetype = {
    markdown = "markdown",
  },

  -- Additional parsers required by Markdown.
  -- These are installed but not started as primary buffer parsers.
  parser_dependencies_by_filetype = {
    markdown = {
      "markdown_inline",
    },
  },
}

function M.setup()
  require("lsp.servers.marksman").setup()
  require("langs.markdown.lint").setup()
  require("langs.markdown.toc").setup()
  require("langs.markdown.mermaid").setup()
end

return M
