-- Stage 13: LaTeX language pack.
--
-- Tree-sitter provides LaTeX syntax parsing and highlighting.
-- Tectonic provides LaTeX compilation.

local M = {
  parser_by_filetype = {
    tex = "latex",
    plaintex = "latex",
  },

  executables = {
    tectonic = "tectonic",
  },
}

return M
