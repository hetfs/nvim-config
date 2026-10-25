-- Stage 09: Lua language pack.
-- LuaLS is an external executable; Neovim owns LSP configuration and activation.

local M = {}

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
