-- Native Neovim options.

local opt = vim.opt

-- Resolve the Windows shell explicitly when it is available.
if vim.fn.has("win32") == 1 then
  local windows_shell = vim.env.ComSpec

  if windows_shell and vim.fn.executable(windows_shell) == 1 then
    opt.shell = windows_shell
  end
end

-- Editor behavior.
opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.wrap = false
opt.breakindent = true
opt.linebreak = true

-- Indentation.
opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.softtabstop = 2
opt.shiftround = true

-- Search.
opt.ignorecase = true
opt.smartcase = true
opt.incsearch = true
opt.hlsearch = true

-- Windows and interface.
opt.splitright = true
opt.splitbelow = true
opt.signcolumn = "yes"
opt.showmode = false
opt.termguicolors = true
opt.mouse = "a"
opt.laststatus = 2

-- Viewport positioning.
opt.scrolloff = 8
opt.sidescrolloff = 8

-- Responsiveness.
opt.updatetime = 250
opt.timeoutlen = 400

-- Completion.
opt.completeopt = {
  "menu",
  "menuone",
  "noselect",
}

-- Files and undo.
opt.fileencoding = "utf-8"
opt.undofile = true
opt.confirm = true

-- Keep the interface uncluttered by default.
opt.list = false
