
-- Native Neovim options.
-- Reference: :help option-list

local opt = vim.opt

-- ============================================================
-- Shell
-- ============================================================

-- Windows: prefer PowerShell 7, with Windows PowerShell fallback.
if vim.fn.has("win32") == 1 then
  local shell = vim.fn.executable("pwsh") == 1 and "pwsh" or "powershell"

  opt.shell = shell

  local shellcmdflag = table.concat({
    "-NoLogo",
    "-NoProfile",
    "-ExecutionPolicy RemoteSigned",
    "-Command",
  }, " ")

  local shell_init = table.concat({
    "[Console]::InputEncoding = [System.Text.UTF8Encoding]::new();",
    "[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new();",
    "$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8';",
  }, " ")

  if shell == "pwsh" then
    shell_init = shell_init .. " $PSStyle.OutputRendering = 'PlainText';"
  end

  opt.shellcmdflag = shellcmdflag .. " " .. shell_init

  -- PowerShell-compatible redirection.
  opt.shellredir = "> %s 2>&1"
  opt.shellpipe = "> %s 2>&1"
  opt.shellquote = ""
  opt.shellxquote = ""
  opt.shelltemp = false
end

-- ============================================================
-- Editor Behavior
-- ============================================================

opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.wrap = false
opt.breakindent = true
opt.mouse = "a"
opt.showmode = false
opt.confirm = true

-- ============================================================
-- Indentation
-- ============================================================

opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.softtabstop = 2
opt.shiftround = true

-- ============================================================
-- Search
-- ============================================================

opt.ignorecase = true
opt.smartcase = true
opt.incsearch = true
opt.hlsearch = true
opt.inccommand = "split"

-- ============================================================
-- Window Management and Scrolling
-- ============================================================

opt.splitright = true
opt.splitbelow = true
opt.scrolloff = 10
opt.sidescrolloff = 10
opt.smoothscroll = true

-- ============================================================
-- Display and Interface
-- ============================================================

opt.list = true

opt.listchars = {
  tab = "» ",
  trail = "·",
  nbsp = "␣",
}

opt.signcolumn = "yes"
opt.laststatus = 3
opt.statusline = "%f %m%r%h%w %= %y %l:%c %p%%"
opt.termguicolors = true
opt.pumblend = 10
opt.winblend = 10

-- ============================================================
-- Clipboard
-- ============================================================

opt.clipboard = "unnamedplus"

-- ============================================================
-- Grep
-- ============================================================

if vim.fn.executable("rg") == 1 then
  opt.grepprg = "rg --vimgrep --smart-case"
  opt.grepformat = "%f:%l:%c:%m"
end

-- ============================================================
-- Folding
-- ============================================================

opt.foldenable = false
opt.foldlevel = 99

-- Enable after Treesitter folding has been validated.
-- opt.foldmethod = "expr"
-- opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"

-- ============================================================
-- Responsiveness and Input Timing
-- ============================================================

opt.updatetime = 250
opt.timeoutlen = 400

-- ============================================================
-- Completion
-- ============================================================

opt.completeopt = {
  "menu",
  "menuone",
  "noselect",
}

-- ============================================================
-- Diagnostics
-- ============================================================

vim.diagnostic.config({
  virtual_text = true,
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
})

-- ============================================================
-- Files and Undo
-- ============================================================

opt.fileencoding = "utf-8"
opt.undofile = true
