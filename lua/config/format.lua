-- Stage 11: Manual formatting through Conform.
-- Formatters come from language packs. No format-on-save and no LSP fallback.

local M = {}
local formatters_by_ft

function M.format()
  local conform = require("conform")
  local bufnr = vim.api.nvim_get_current_buf()
  local filetype = vim.bo[bufnr].filetype
  local configured = formatters_by_ft[filetype]

  if not configured or #configured == 0 then
    vim.notify(string.format("Format: no formatter configured for '%s'", filetype), vim.log.levels.WARN)
    return
  end

  local available = conform.list_formatters_to_run(bufnr)

  if #available == 0 then
    local unavailable = {}

    for _, name in ipairs(configured) do
      local info = conform.get_formatter_info(name, bufnr)

      if not info or not info.available then
        unavailable[#unavailable + 1] = name
      end
    end

    local message

    if #unavailable > 0 then
      message = string.format("Format: formatter executable unavailable: %s", table.concat(unavailable, ", "))
    else
      message = string.format("Format: no runnable formatter found for '%s'", filetype)
    end

    vim.notify(message, vim.log.levels.WARN)
    return
  end

  conform.format({
    bufnr = bufnr,
    async = true,
    lsp_format = "never",
  })
end

function M.setup()
  formatters_by_ft = require("langs").collect("formatters")

  require("conform").setup({
    formatters_by_ft = formatters_by_ft,
    default_format_opts = {
      lsp_format = "never",
    },
  })

  vim.api.nvim_create_user_command("Format", M.format, {
    desc = "Format current buffer",
  })
end

return M
