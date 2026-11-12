-- Stage 13: MDX language pack.
--
-- The MDX language server provides diagnostics and
-- TypeScript-backed language features. nvim-lspconfig
-- supplies the server definition, default filetypes,
-- root markers, and TypeScript SDK discovery.
--
-- dprint formats MDX through dprint-plugin-mdx and
-- supports TypeScript formatting in embedded code blocks.
--
-- Tree-sitter uses the custom MDX parser registered
-- by lua/plugins/treesitter.lua.

local M = {
  formatters = {
    mdx = { "dprint" },
  },

  parser_by_filetype = {
    mdx = "mdx",
  },
}

function M.setup()
  local executable = vim.fn.exepath("mdx-language-server")

  if executable == "" then
    vim.notify("MDX language server not found: mdx-language-server", vim.log.levels.WARN)
    return
  end

  -- Extend the nvim-lspconfig server definition.
  -- Preserve its default filetypes, root markers,
  -- and before_init TypeScript SDK discovery.
  vim.lsp.config("mdx_analyzer", {
    cmd = {
      executable,
      "--stdio",
    },

    init_options = {
      typescript = {
        enabled = true,
      },
    },
  })

  vim.lsp.enable("mdx_analyzer")
end

return M
