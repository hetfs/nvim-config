-- Shared vtsls integration for independently activated JavaScript
-- and TypeScript language packs.
--
-- Enabled language packs determine which filetypes vtsls handles.

local M = {}

local configured = false

local filetypes_by_pack = {
  javascript = {
    "javascript",
    "javascriptreact",
  },

  typescript = {
    "typescript",
    "typescriptreact",
  },
}

function M.setup()
  if configured then
    return
  end

  local config = require("config.languages")
  local enabled_packs = config.packs or {}
  local filetypes = {}

  for pack, pack_filetypes in pairs(filetypes_by_pack) do
    if enabled_packs[pack] == true then
      vim.list_extend(filetypes, pack_filetypes)
    end
  end

  if #filetypes == 0 then
    return
  end

  if vim.fn.executable("vtsls") ~= 1 then
    return
  end

  table.sort(filetypes)

  vim.lsp.config("vtsls", {
    filetypes = filetypes,
  })

  vim.lsp.enable("vtsls")

  configured = true
end

return M
