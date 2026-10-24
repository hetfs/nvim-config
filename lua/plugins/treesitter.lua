-- Stage 08: Tree-sitter.
-- Keep plugin loading eager and parser installation explicit.

vim.pack.add({
  {
    src = "https://github.com/nvim-treesitter/nvim-treesitter",
    name = "nvim-treesitter",
  },
})

-- Configure the parser and query installation directory.
require("nvim-treesitter").setup({
  install_dir = vim.fn.stdpath("data") .. "/site",
})

-- Enable native Tree-sitter highlighting for Lua while validating
-- parser installation and compiler compatibility.
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("nvim_config_treesitter", {
    clear = true,
  }),
  pattern = { "lua" },
  desc = "Enable Tree-sitter highlighting for Lua",
  callback = function(event)
    vim.treesitter.start(event.buf)
  end,
})
