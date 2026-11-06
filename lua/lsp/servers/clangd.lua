-- Shared clangd integration for independently activated C and C++
-- language packs.
--
-- Enabled language packs determine which filetypes clangd handles.
-- Compiler discovery is restricted to the matching installed toolchains.

local M = {}

local configured = false

local packs = {
  c = {
    filetypes = { "c" },
    drivers = { "gcc" },
  },

  cpp = {
    filetypes = { "cpp" },
    drivers = { "g++" },
  },
}

function M.setup()
  if configured then
    return
  end

  local config = require("config.languages")
  local enabled_packs = config.packs or {}

  local filetypes = {}
  local drivers = {}

  for pack, settings in pairs(packs) do
    if enabled_packs[pack] == true then
      vim.list_extend(filetypes, settings.filetypes)

      for _, driver in ipairs(settings.drivers) do
        local path = vim.fn.exepath(driver)

        if path ~= "" then
          drivers[#drivers + 1] = path
        end
      end
    end
  end

  if #filetypes == 0 then
    return
  end

  local clangd = vim.fn.exepath("clangd")

  if clangd == "" then
    return
  end

  table.sort(filetypes)
  table.sort(drivers)

  local cmd = { clangd }

  if #drivers > 0 then
    cmd[#cmd + 1] = "--query-driver=" .. table.concat(drivers, ",")
  end

  vim.lsp.config("clangd", {
    cmd = cmd,
    filetypes = filetypes,
  })

  vim.lsp.enable("clangd")

  configured = true
end

return M
