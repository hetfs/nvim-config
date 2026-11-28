-- Stage: PowerShell development.
-- PowerShell Editor Services integration and terminal workflows.
--
-- Requirements:
--   - PowerShell 7
--   - PowerShell Editor Services
--   - powershell.nvim

vim.pack.add({
  {
    src = "https://github.com/TheLeoP/powershell.nvim",
    name = "powershell.nvim",
  },
})

require("powershell").setup({
  shell = "C:/Program Files/PowerShell/7/pwsh.exe",

  bundle_path = vim.fn.expand(
    "~/AppData/Local/Programs/PSES/PowerShellEditorServices"
  ),

  lsp_log_level = "Warning",

  settings = {
    powershell = {
      rename = {
        acceptDisclaimer = true,
      },
    },
  },
})

-- ---------------------------------------------------------------------------
-- PowerShell workflows.
-- ---------------------------------------------------------------------------

local map = vim.keymap.set

-- Open a PowerShell terminal in a horizontal split.
map("n", "<leader>ps", function()
  vim.cmd("split")
  vim.cmd("terminal pwsh")
end, {
  desc = "PowerShell: Open terminal",
})

-- Open a PowerShell terminal in a vertical split.
map("n", "<leader>pS", function()
  vim.cmd("vsplit")
  vim.cmd("terminal pwsh")
end, {
  desc = "PowerShell: Open vertical terminal",
})

