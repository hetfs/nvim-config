-- Shared Emmet language-server integration.
--
-- Emmet is an optional productivity tool, independent of language packs.
-- Activation is controlled by config.languages.tools.emmet.

local M = {}

local configured = false

local filetypes = {
  "html",
  "css",
  "scss",
  "javascriptreact",
  "typescriptreact",
}

function M.setup()
  if configured then
    return
  end

  local config = require("config.languages")

  if not config.tools or config.tools.emmet ~= true then
    return
  end

  if vim.fn.executable("emmet-language-server") ~= 1 then
    return
  end

  vim.lsp.config("emmet_ls", {
    cmd = {
      "emmet-language-server",
      "--stdio",
    },
    filetypes = filetypes,
  })

  vim.lsp.enable("emmet_ls")

  configured = true
end

return M
