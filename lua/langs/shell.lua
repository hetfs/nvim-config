return {
  name = "shell",

  filetypes = {
    "sh",
    "bash",
  },

  -- Server definitions come from nvim-lspconfig.
  -- Activation uses Neovim's native LSP API.
  lsp = {
    bashls = {
      cmd = {
        "bash-language-server",
        "start",
      },

      filetypes = {
        "sh",
        "bash",
      },

      settings = {
        bashIde = {
          shellcheckPath = "shellcheck",
        },
      },
    },
  },

  -- shfmt uses .editorconfig when the filename is provided.
  -- Keep formatter preferences outside this language pack.
  formatters = {
    sh = { "shfmt" },
    bash = { "shfmt" },
  },

  -- External dependencies are managed outside Neovim.
  tools = {
    "bash",
    "bash-language-server",
    "shellcheck",
    "shfmt",
  },
}
