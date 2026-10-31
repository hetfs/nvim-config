
-- Stage 08: Tree-sitter.
-- Keep plugin loading eager and parser installation explicit.

vim.pack.add({
  {
    src = "https://github.com/nvim-treesitter/nvim-treesitter",
    name = "nvim-treesitter",
  },
})

-- On Windows, expose the built-in tar executable when it is missing from PATH.
if vim.fn.has("win32") == 1 and vim.fn.executable("tar") == 0 then
  local windir = vim.env.WINDIR

  if windir and windir ~= "" then
    local tar = vim.fs.joinpath(windir, "System32", "tar.exe")

    if vim.fn.executable(tar) == 1 then
      local dir = vim.fs.dirname(tar)
      vim.env.PATH = dir .. ";" .. (vim.env.PATH or "")
    end
  end
end

-- On Windows, use GCC for parser builds when CC is not already configured.
if vim.fn.has("win32") == 1 and (not vim.env.CC or vim.env.CC == "") then
  local gcc = vim.fn.exepath("gcc")

  if gcc ~= "" then
    vim.env.CC = gcc
  end
end

-- Configure the parser and query installation directory.
require("nvim-treesitter").setup({
  install_dir = vim.fn.stdpath("data") .. "/site",
})

-- Enable native Tree-sitter highlighting for supported filetypes.
-- JSONC uses the JSON parser; JSON5 uses its own parser.
-- YAML variants use the YAML parser; TOML uses the TOML parser.
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("nvim_config_treesitter", {
    clear = true,
  }),
  pattern = {
    "lua",
    "python",
    "yaml",
    "yaml.docker-compose",
    "yaml.ansible",
    "yaml.gitlab",
    "yaml.helm-values",
    "json",
    "jsonc",
    "json5",
    "toml",
  },
  desc = "Enable Tree-sitter highlighting for supported filetypes",
  callback = function(event)
    vim.treesitter.start(event.buf)
  end,
})
