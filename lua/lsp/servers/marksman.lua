-- Marksman language-server integration for Markdown.
--
-- Markdown pack activation controls whether Marksman is configured.
-- The executable must be installed outside Neovim.

local M = {}

local configured = false

function M.setup()
  if configured then
    return
  end

  -- Resolve the externally installed Marksman executable.
  local marksman = vim.fn.exepath("marksman")

  if marksman == "" then
    return
  end

  -- Configure Marksman using Neovim's native LSP API.
  vim.lsp.config("marksman", {
    cmd = {
      marksman,
      "server",
    },
    filetypes = {
      "markdown",
    },
    root_markers = {
      ".marksman.toml",
      ".git",
    },
  })

  vim.lsp.enable("marksman")

  configured = true
end

return M
