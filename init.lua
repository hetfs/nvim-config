-- nvim-config
-- Native-first, modular Neovim configuration.
-- Minimum supported version: Neovim 0.12.

if vim.fn.has("nvim-0.12") ~= 1 then
  error(
    string.format("nvim-config requires Neovim >= 0.12.0; detected %s.", tostring(vim.version())),
    0
  )
end

-- Resolve this configuration's root directory.
local source = debug.getinfo(1, "S").source
local init_path = source:sub(1, 1) == "@" and source:sub(2) or source
local config_root = vim.fn.fnamemodify(vim.fn.resolve(init_path), ":p:h")

-- Make this configuration's Lua modules discoverable.
vim.opt.runtimepath:prepend(config_root)

-- Leader keys must exist before any module defines mappings.
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Stage 03: required modules load directly, in a fixed order.
-- A failing require aborts the remaining startup sequence.
require("config.options")
require("config.keymaps")
require("config.autocmds")
