-- Stage 13: Docker language pack.
-- Docker owns Dockerfile support and Docker Language Server activation.
-- Compose YAML support remains shared with the data language pack.

local M = {
  formatters = {
    dockerfile = { "dockerfmt" },
  },

  parsers = {
    "dockerfile",
  },

  parser_by_filetype = {
    dockerfile = "dockerfile",
  },

  servers = {
    docker_language_server = true,
  },

  executables = {
    docker_language_server = "docker-language-server",
  },
}

local function enable(server, config)
  local executable = assert(
    M.executables[server],
    string.format("No executable configured for Docker server '%s'", server)
  )

  -- Do not enable a server whose executable is unavailable.
  if vim.fn.executable(executable) ~= 1 then
    return
  end

  -- Extend the server definition provided by nvim-lspconfig.
  if config then
    vim.lsp.config(server, config)
  end

  -- Use Neovim's native LSP activation API.
  vim.lsp.enable(server)
end

function M.setup()
  enable("docker_language_server", {
    filetypes = {
      "dockerfile",
      "yaml.docker-compose",
    },

    init_options = {
      telemetry = "off",
    },
  })
end

return M
