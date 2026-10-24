-- nvim-config
-- Native-first, modular Neovim configuration.
-- Minimum supported version: Neovim 0.12.

-- Disable unused remote providers.
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0

if vim.fn.has("nvim-0.12") ~= 1 then
  error(string.format("nvim-config requires Neovim >= 0.12.0; detected %s.", tostring(vim.version())), 0)
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
vim.loader.enable() -- Lua bytecode cache for faster startup
vim.g.have_nerd_font = true -- set true if a Nerd Font is active in your terminal

if vim.g.neovide then
  local neovide_font_size = 12
  local font_candidates = {
    "JetBrainsMono Nerd Font",
    "JetBrainsMonoNL Nerd Font",
    "FiraCode Nerd Font",
    "MesloLGS NF",
    "Hack Nerd Font",
    "Noto Sans Mono",
    "Monospace",
  }
  local selected_font = font_candidates[#font_candidates]
  if vim.fn.executable("fc-list") == 1 then
    local out = vim.fn.system({ "fc-list", ":", "family" })
    for _, font_name in ipairs(font_candidates) do
      if out:find(font_name, 1, true) then
        selected_font = font_name
        break
      end
    end
  else
    selected_font = font_candidates[1]
  end

  vim.o.guifont = string.format("%s:h%d", selected_font, neovide_font_size)
end
-- Required modules load directly, in a fixed order.
-- A failing require aborts the remaining startup sequence.
require("config.options")
require("plugins.colorscheme")
require("plugins.icons")
require("config.keymaps")
require("config.autocmds")
require("plugins.which-key")
