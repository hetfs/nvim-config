local M = {
  formatters = {
    ps1 = { "powershell_formatter" },
    psm1 = { "powershell_formatter" },
    psd1 = { "powershell_formatter" },
  },

  parser_by_filetype = {
    ps1 = "powershell",
    psm1 = "powershell",
    psd1 = "powershell",
  },
}

function M.setup()
  -- PowerShell LSP initialization is owned by powershell.nvim.
end

return M
