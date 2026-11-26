-- nvim-config
-- Native-first, modular Neovim configuration.
-- Minimum supported version: Neovim 0.12.

-- ============================================================
-- Core Requirements
-- ============================================================

-- Disable unused remote providers.
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0

-- Enforce the minimum supported Neovim version.
if vim.fn.has("nvim-0.12") ~= 1 then
  local version = vim.version()
  local detected = string.format("%d.%d.%d", version.major, version.minor, version.patch)

  error(string.format("nvim-config requires Neovim >= 0.12.0; detected %s.", detected), 0)
end

-- ============================================================
-- Configuration Root
-- ============================================================

-- Resolve this configuration's root directory.
local source = debug.getinfo(1, "S").source
local init_path = source:sub(1, 1) == "@" and source:sub(2) or source
local config_root = vim.fn.fnamemodify(vim.fn.resolve(init_path), ":p:h")

-- Make this configuration's Lua modules discoverable.
vim.opt.runtimepath:prepend(config_root)

-- ============================================================
-- Global Settings
-- ============================================================

-- Define leader keys before loading any keymaps.
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Enable Lua bytecode caching.
vim.loader.enable()

-- Set this according to the font used by the terminal or GUI.
vim.g.have_nerd_font = true

-- ============================================================
-- Neovide
-- ============================================================

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

  -- Use a platform-appropriate fallback when font discovery
  -- is unavailable.
  local selected_font

  if vim.fn.has("win32") == 1 then
    selected_font = "Consolas"
  elseif vim.fn.has("macunix") == 1 then
    selected_font = "Menlo"
  else
    selected_font = "Monospace"
  end

  -- fc-list is available on many Linux systems and can also
  -- be installed on macOS. It is not normally available on Windows.
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

-- ============================================================
-- Core Options and Appearance
-- ============================================================

require("config.options")
require("config.filetypes")
require("plugins.colorscheme")
require("plugins.icons")
require("plugins.trouble")

-- ============================================================
-- Navigation Plugins
-- ============================================================

-- Snacks must load before Yanky because Yanky registers
-- its Snacks Picker integration during setup.
require("plugins.snacks")
require("plugins.yanky")
require("plugins.fzf-lua")
require("plugins.flash")
require("plugins.spider")
require("plugins.harpoon")
require("plugins.grug-far")
require("plugins.todo-comments")

-- ============================================================
-- Editing Plugins
-- ============================================================

require("plugins.mini-ai")
require("plugins.mini-surround")
require("plugins.mini-move")
require("plugins.dial")
require("plugins.csvview")

-- ============================================================
-- Syntax Parsing and Highlighting
-- ============================================================

require("plugins.treesitter")
require("plugins.ts-autotag")

-- ============================================================
-- Markdown
-- ============================================================

require("plugins.md-render")

-- ============================================================
-- LSP and Language Tooling
-- ============================================================

-- Load LSP server definitions and language-specific integrations.
require("plugins.lsp")
require("plugins.powershell")

-- Configure shell integration.
require("plugins.shell").setup()

-- Configure Lua development support.
require("plugins.lazydev")
require("plugins.neotest")

-- ============================================================
-- completion and snippets
-- ============================================================

require("plugins.blink-cmp")
require("plugins.friendly-snippets")
require("plugins.mini-pairs")

-- ============================================================
-- optional ai integrations
-- ============================================================

-- ai activation is independent of language-pack activation.
local ai = require("config.ai")

assert(type(ai.enabled) == "boolean", "ai configuration 'enabled' must be boolean")

assert(type(ai.providers) == "table", "ai configuration must define a 'providers' table")

for name, enabled in pairs(ai.providers) do
  assert(type(name) == "string" and name ~= "", "ai provider names must be non-empty strings")

  assert(type(enabled) == "boolean", string.format("ai provider configuration for '%s' must be boolean", name))
end

if ai.enabled then
  if ai.providers.blink_edit then
    require("plugins.blink-edit").setup()
  end

  if ai.providers.codecompanion then
    require("plugins.codecompanion").setup()
  end
end

-- ============================================================
-- general configuration
-- ============================================================

-- load centralized keymaps after their required plugins.
require("config.keymaps")

-- configure native lsp behavior and buffer-local integrations.
require("config.lsp")
require("plugins.illuminate")

-- configure cmake workflows.
require("config.cmake").setup()

-- ============================================================
-- shared lsp integrations
-- ============================================================

require("lsp.servers.emmet").setup()

-- ============================================================
-- language packs
-- ============================================================

-- activate explicitly enabled language packs.
require("langs").setup()

-- ============================================================
-- rust and cargo
-- ============================================================

-- configure native rust and cargo workflows only when
-- the rust language pack is enabled.
if require("config.languages").packs.rust then
  require("config.rust").setup()
end

-- ============================================================
-- formatting
-- ============================================================

-- conform reads formatter metadata from the activated language packs.
require("plugins.conform")
require("config.format").setup()

-- ============================================================
-- autocommands
-- ============================================================

require("config.autocmds")

-- ============================================================
-- git and sessions
-- ============================================================

require("plugins.gitsigns")
require("plugins.diffview")
require("plugins.git-conflict")
require("plugins.octo")
require("plugins.project")
require("plugins.mini-sessions")

-- ui plugins.
require("plugins.lualine")
-- require("plugins.bufferline")
-- require("plugins.zen-mode")
-- require("plugins.noice")

-- ============================================================
-- keymap discovery
-- ============================================================

-- configure keymap discovery after plugin and workflow mappings
-- have been registered.
require("plugins.which-key")
