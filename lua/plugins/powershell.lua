vim.pack.add({
  {
    src = "https://github.com/TheLeoP/powershell.nvim",
    name = "powershell.nvim",
  },
})

require("powershell").setup({
  shell = "C:/Program Files/PowerShell/7/pwsh.exe",
  bundle_path = vim.fn.expand("~/AppData/Local/Programs/PSES/PowerShellEditorServices"),
  lsp_log_level = "Warning",
  settings = {
    powershell = {
      rename = {
        acceptDisclaimer = true,
      },
    },
  },
})

-- PowerShell and LSP workflows.

local map = vim.keymap.set

-- PowerShell terminal workflows.
map("n", "<leader>ps", function()
  vim.cmd("split")
  vim.cmd("terminal pwsh")
end, {
  desc = "PowerShell: Open terminal",
})

map("n", "<leader>pS", function()
  vim.cmd("vsplit")
  vim.cmd("terminal pwsh")
end, {
  desc = "PowerShell: Open vertical terminal",
})
