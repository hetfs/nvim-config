-- Stage 09: Shared native Language Server Protocol behavior.
-- Language-specific configuration belongs in lua/langs/.

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("nvim_config_lsp", {
    clear = true,
  }),
  desc = "Set LSP buffer-local keymaps",
  callback = function(event)
    require("config.keymaps").lsp(event.buf)
  end,
})
