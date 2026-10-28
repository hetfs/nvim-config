-- Stage 09: Lua language pack.
-- LuaLS is an external executable; Neovim owns LSP configuration and activation.
-- Stage 11: Formatter metadata is declared by the language pack.

local M = {
  formatters = {
    lua = { "stylua" },
  },
}

function M.setup()
  vim.lsp.config("lua_ls", {
    settings = {
      Lua = {
        runtime = {
          version = "LuaJIT",
        },
        diagnostics = {
          globals = { "vim" },
        },

        workspace = {

          checkThirdParty = false,
        },
        telemetry = {
          enable = false,
        },
      },
    },
  })

  vim.lsp.enable("lua_ls")
end

return M
