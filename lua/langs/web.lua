
-- Stage 13: Optional web language pack.
-- HTML language intelligence is provided by vscode-html-language-server.
-- Neovim's native LSP API owns configuration and activation.
-- Conform owns formatting through the shared formatter registry.
-- Emmet is optional and disabled by default.

local M = {
  formatters = {
    html = { "prettier" },
  },

  filetypes = {
    html = {
      "html",
    },
  },

  parsers = {
    "html",
    "css",
    "javascript",
  },

  servers = {
    "html",
  },

  executables = {
    html = "vscode-html-language-server",
  },
}

local function enable(server, config)
  local executable = assert(
    M.executables[server],
    string.format("No executable declared for web server '%s'", server)
  )

  if config then
    vim.lsp.config(server, config)
  end

  if vim.fn.executable(executable) == 1 then
    vim.lsp.enable(server)
  end
end

local function setup_html()
  enable("html", {
    init_options = {
      -- Formatting belongs to Conform.
      provideFormatter = false,

      -- Enable embedded CSS and JavaScript intelligence.
      embeddedLanguages = {
        css = true,
        javascript = true,
      },

      configurationSection = {
        "html",
        "css",
        "javascript",
      },
    },

    settings = {
      html = {
        validate = {
          scripts = true,
          styles = true,
        },

        hover = {
          documentation = true,
          references = true,
        },
      },
    },
  })
end

local function setup_emmet()
  if vim.g.config_web_emmet ~= true then
    return
  end

  if vim.fn.executable("emmet-language-server") ~= 1 then
    vim.notify(
      "Emmet is enabled but emmet-language-server was not found in PATH.",
      vim.log.levels.WARN,
      { title = "HTML" }
    )
    return
  end

  vim.lsp.config("emmet_language_server", {
    cmd = {
      "emmet-language-server",
      "--stdio",
    },

    filetypes = {
      "html",
      "css",
    },

    root_markers = {
      ".git",
    },
  })

  vim.lsp.enable("emmet_language_server")
end

function M.setup()
  setup_html()
  setup_emmet()
end

return M
