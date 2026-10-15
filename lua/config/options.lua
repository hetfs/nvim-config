-- Native Neovim options.
-- Reference: :help option-list
--
--

local opt = vim.opt

-- Shell.
-- Prefer the configured Windows command processor when available.
if vim.fn.has("win32") == 1 then
  local windows_shell = vim.env.ComSpec

  if windows_shell and vim.fn.executable(windows_shell) == 1 then
    opt.shell = windows_shell
  end
end

-- Clipboard.
-- Use the system clipboard for yank, delete, change, and put operations.
opt.clipboard = "unnamedplus"

-- Editor behavior.
opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.wrap = false
opt.breakindent = true
opt.mouse = "a"

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

-- Windows.
opt.splitright = true
opt.splitbelow = true

-- Display and interface.
opt.list = false
opt.listchars = {
  tab = "» ",
  trail = "·",
  nbsp = "␣",
}
opt.signcolumn = "yes"
opt.showmode = false
opt.laststatus = 3
opt.statusline = "%f %m%r%h%w %= %y %l:%c %p%%" -- Native statusline.
opt.termguicolors = true
opt.pumblend = 10
opt.winblend = 10
opt.smoothscroll = true
opt.inccommand = "split"

-- Viewport positioning.
opt.scrolloff = 10
opt.sidescrolloff = 10

-- Folding.
-- Keep folding independent of Treesitter until its stage is implemented.
-- opt.foldmethod = "expr"
-- opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
opt.foldenable = false

-- Responsiveness and input timing.
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
