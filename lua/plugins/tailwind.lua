-- Stage 27: Tailwind CSS integration.
-- Enable Tailwind CSS LSP and buffer color highlighting.
--
-- Dependencies:
--   - nvim-lspconfig: Tailwind CSS LSP configuration
--   - @tailwindcss/language-server: Tailwind CSS language server
--   - Node.js and npm
--
-- Completion:
--   - Blink.cmp is managed separately.
--   - No nvim-cmp integration is required.
--
-- Plugin installed here:
--   - NvChad/nvim-colorizer.lua

-- ============================================================
-- Plugin installation
-- ============================================================

vim.pack.add({
  {
    src = "https://github.com/NvChad/nvim-colorizer.lua",
    name = "nvim-colorizer.lua",
  },
})

-- ============================================================
-- Tailwind CSS Language Server
-- ============================================================

-- Install with:
--   npm install --global @tailwindcss/language-server
--
-- nvim-lspconfig provides the server definition.
-- Neovim 0.11+ uses vim.lsp.enable().

vim.lsp.enable("tailwindcss")

-- ============================================================
-- Tailwind CSS buffer color highlighting
-- ============================================================

require("colorizer").setup({
  filetypes = {
    "html",
    "css",
    "scss",
    "sass",
    "less",
    "javascript",
    "javascriptreact",
    "typescript",
    "typescriptreact",
    "vue",
    "svelte",
    "astro",
    "php",
    "blade",
    "mdx",
    "markdown",
    "html-eex",
    "heex",
    "templ",
  },

  options = {
    parsers = {
      tailwind = {
        enable = true,

        -- Obtain additional Tailwind colors from the LSP.
        lsp = true,
      },
    },
  },
})

