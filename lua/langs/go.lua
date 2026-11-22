-- Stage 13: Go language pack.
--
-- Go owns its formatter, Tree-sitter parser metadata,
-- template filetype registration, and LSP activation.
-- The upstream nvim-lspconfig definition supplies gopls.

local M = {
  formatters = {
    go = { "gofmt" },
  },

  parser_by_filetype = {
    go = "go",
    gomod = "gomod",
    gowork = "gomod",
    gotmpl = "gotmpl",
  },
}

function M.setup()
  -- Register standard Go template extensions.
  --
  -- The .tmpl association also covers compound extensions
  -- such as .html.tmpl and .yaml.tmpl.
  vim.filetype.add({
    extension = {
      tmpl = "gotmpl",
      gotmpl = "gotmpl",
      gohtml = "gotmpl",
    },
  })

  -- Configure gopls template support.
  vim.lsp.config("gopls", {
    settings = {
      gopls = {
        templateExtensions = {
          "tmpl",
          "gotmpl",
          "gohtml",
        },
      },
    },
  })

  -- Use native Neovim LSP activation.
  vim.lsp.enable("gopls")
end

return M
