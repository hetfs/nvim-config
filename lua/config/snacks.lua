-- Windows compatibility for Snacks image language discovery.

local M = {}

function M.setup()
  if vim.fn.has("win32") ~= 1 then
    return
  end

  local image = require("snacks.image")

  image.langs = function()
    local languages = {}
    local seen = {}

    local queries = vim.api.nvim_get_runtime_file(
      "queries/*/images.scm",
      true
    )

    for _, query in ipairs(queries) do
      local normalized = query:gsub("\\", "/")
      local language = normalized:match("queries/(.-)/images%.scm")

      if language and not seen[language] then
        seen[language] = true
        languages[#languages + 1] = language
      end
    end

    table.sort(languages)

    return languages
  end
end

return M

