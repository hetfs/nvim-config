-- nvim-config
-- Native-first, modular Neovim configuration.
-- Minimum supported version: Neovim 0.12.

-- Disable unused remote providers.
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0

-- Enforce the minimum supported Neovim version.
if vim.fn.has("nvim-0.12") ~= 1 then
  error(string.format("nvim-config requires Neovim >= 0.12.0; detected %s.", tostring(vim.version())), 0)
end

-- Resolve this configuration's root directory.
local source = debug.getinfo(1, "S").source
local init_path = source:sub(1, 1) == "@" and source:sub(2) or source
local config_root = vim.fn.fnamemodify(vim.fn.resolve(init_path), ":p:h")

-- Make this configuration's Lua modules discoverable.
vim.opt.runtimepath:prepend(config_root)

-- Define leader keys before loading any keymaps.
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Enable Lua bytecode caching.
vim.loader.enable()

-- Set this according to the font used by the terminal or GUI.
vim.g.have_nerd_font = true

-- Configure the Neovide font when running in Neovide.
if vim.g.neovide then
  local font_size = 12
  local font_candidates = {
    "JetBrainsMono Nerd Font",
    "JetBrainsMonoNL Nerd Font",
    "FiraCode Nerd Font",
    "MesloLGS NF",
    "Hack Nerd Font",
    "Noto Sans Mono",
    "Monospace",
  }

  -- Use a platform-appropriate fallback when font discovery is unavailable.
  local selected_font
  if vim.fn.has("win32") == 1 then
    selected_font = "Consolas"
  elseif vim.fn.has("mac") == 1 then
    selected_font = "Menlo"
  else
    selected_font = "Monospace"
  end

  -- fc-list is available on many Linux systems, but not normally on Windows.
  if vim.fn.executable("fc-list") == 1 then
    local output = vim.fn.system({ "fc-list", ":", "family" })

    if vim.v.shell_error == 0 then
      for _, font_name in ipairs(font_candidates) do
        if output:find(font_name, 1, true) then
          selected_font = font_name
          break
        end
      end
    end
  end

  vim.o.guifont = string.format("%s:h%d", selected_font, font_size)
end

-- Load required modules directly in a fixed order.
-- A failing require aborts the remaining startup sequence.

-- Core options and appearance.
require("config.options")
require("plugins.colorscheme")
require("plugins.icons")

-- Navigation plugins.
require("plugins.snacks")
require("plugins.fzf-lua")
require("plugins.flash")

-- Editing plugins.
require("plugins.mini-ai")
require("plugins.mini-surround")
require("plugins.mini-move")
require("plugins.dial")

-- General configuration.
require("config.keymaps")
require("config.autocmds")

-- Configure keymap discovery after mappings have been registered.
require("plugins.which-key")
