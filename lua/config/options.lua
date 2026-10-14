-- Native Neovim options.
-- Stage 02: Keymaps and Autocommands.

local opt = vim.opt

-- Line numbers and editing
opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.wrap = false
opt.breakindent = true
opt.linebreak = true
opt.scrolloff = 8
opt.sidescrolloff = 8

-- Indentation
opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.softtabstop = 2
opt.shiftround = true

-- Search
opt.ignorecase = true
opt.smartcase = true
opt.incsearch = true
opt.hlsearch = true

-- Windows and interface
opt.splitright = true
opt.splitbelow = true
opt.signcolumn = "yes"
opt.showmode = false
opt.termguicolors = true
opt.mouse = "a"
opt.laststatus = 2

-- Completion and responsiveness
opt.updatetime = 250
opt.timeoutlen = 400
opt.completeopt = { "menu", "menuone", "noselect" }

-- Files and undo
opt.fileencoding = "utf-8"
opt.undofile = true
opt.confirm = true

-- Whitespace display remains disabled until explicitly enabled.
opt.list = false
