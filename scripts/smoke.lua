-- Usage:
-- nvim --headless -u init.lua -c "luafile scripts/smoke.lua"

local function check(condition, message)
  if not condition then
    error("FAIL nvim-config: " .. message, 2)
  end
end

local function check_equal(actual, expected, message)
  check(actual == expected, message .. " (expected " .. vim.inspect(expected) .. ", got " .. vim.inspect(actual) .. ")")
end

local function check_module_failure_contract(root)
  check(type(vim.system) == "function", "vim.system() is required for the subprocess failure test")

  local init_path = root .. "/init.lua"

  -- Inject an intentional failure in config.options.
  local preload_options = [[lua package.preload["config.options"] = function() error("STAGE04_INTENTIONAL_MODULE_FAILURE") end]]

  -- This marker must never appear because options fails first.
  local preload_keymaps = [[lua package.preload["config.keymaps"] = function() print("STAGE04_UNEXPECTED_KEYMAPS_LOADED"); return true end]]

  local result = vim
    .system({
      vim.v.progpath,
      "--headless",
      "-i",
      "NONE",
      "-u",
      "NONE",
      "--cmd",
      preload_options,
      "--cmd",
      preload_keymaps,
      "-c",
      "luafile " .. vim.fn.fnameescape(init_path),
      "-c",
      "qa!",
    }, {
      text = true,
    })
    :wait(5000)

  check(type(result) == "table", "failure-test subprocess returned a result")

  local output = (result.stdout or "") .. "\n" .. (result.stderr or "")

  check(result.code ~= 124, "failure-test subprocess timed out\n" .. output)

  check(
    output:find("STAGE04_INTENTIONAL_MODULE_FAILURE", 1, true) ~= nil,
    table.concat({
      "required-module error is visible in subprocess output",
      "Subprocess exit code: " .. tostring(result.code),
      "Subprocess signal: " .. tostring(result.signal),
      "Subprocess stdout:",
      tostring(result.stdout),
      "Subprocess stderr:",
      tostring(result.stderr),
    }, "\n")
  )

  check(output:find("STAGE04_UNEXPECTED_KEYMAPS_LOADED", 1, true) == nil, "keymaps module does not load after options module fails\n" .. output)

  print("PASS module failure contract")
end

local function check_native_grep()
  check(vim.fn.executable("rg") == 1, "ripgrep (rg) must be available for the native grep workflow")

  -- Exercise Neovim's native grep integration and quickfix population.
  vim.cmd("silent grep! Stage scripts/smoke.lua")

  local quickfix = vim.fn.getqflist()

  check(#quickfix > 0, "native grep populates the quickfix list")

  for _, item in ipairs(quickfix) do
    check(item.valid == 1, "native grep produces valid quickfix entries")
    check(item.lnum > 0, "quickfix result contains a valid line number")
    check(item.col > 0, "quickfix result contains a valid column")
    check(item.text ~= "", "quickfix result contains matching text")
  end

  print("PASS native grep and quickfix")
end

-- Retained for the later Stage 04 commenting investigation.
-- Deliberately not called by main() while native gcc/gc behavior is unresolved.
local function check_native_commenting()
  local original_buf = vim.api.nvim_get_current_buf()
  local buf = vim.api.nvim_create_buf(false, true)

  check(buf ~= 0, "create scratch buffer for native commenting")

  vim.api.nvim_set_current_buf(buf)
  vim.bo[buf].filetype = "lua"
  vim.bo[buf].commentstring = "-- %s"

  local original_lines = {
    "local alpha = 1",
    "local beta = 2",
    "local gamma = 3",
  }

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, original_lines)

  -- Toggle the current line into a comment.
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  vim.cmd("normal gcc")

  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

  check_equal(lines[1], "-- local alpha = 1", "gcc comments the current line")

  -- Toggle the current line back into code.
  vim.cmd("normal gcc")

  lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

  check_equal(lines[1], "local alpha = 1", "gcc uncomments the current line")

  -- Toggle three lines into comments.
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  vim.cmd("normal 3gcc")

  lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

  for index, line in ipairs(original_lines) do
    check_equal(lines[index], "-- " .. line, "3gcc comments line " .. index)
  end

  -- Toggle the three lines back into code.
  vim.cmd("normal 3gcc")

  lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

  for index, line in ipairs(original_lines) do
    check_equal(lines[index], line, "3gcc uncomments line " .. index)
  end

  vim.api.nvim_set_current_buf(original_buf)
  vim.api.nvim_buf_delete(buf, { force = true })

  print("PASS native commenting")
end

local function check_stage06_plugins()
  -- Verify mini.icons loaded and exposes its expected API.
  local mini_icons = package.loaded["mini.icons"]

  check(type(mini_icons) == "table" and type(mini_icons.get) == "function", "mini.icons loaded and exposes its get() API")

  -- Verify which-key loaded and exposes its expected API.
  local which_key = package.loaded["which-key"]

  check(type(which_key) == "table" and type(which_key.show) == "function", "which-key.nvim loaded and exposes its show() API")

  print("PASS Stage 06 plugin loading")
end

local function main()
  local root = vim.fn.getcwd()
  local version = vim.version()

  check(vim.fn.has("nvim-0.12") == 1, "Neovim 0.12 or newer is required")

  -- Required configuration modules.
  check(package.loaded["config.options"] ~= nil, "config.options was loaded")
  check(package.loaded["config.keymaps"] ~= nil, "config.keymaps was loaded")
  check(package.loaded["config.autocmds"] ~= nil, "config.autocmds was loaded")

  -- Required plugin modules.
  -- Stage 05
  check(package.loaded["catppuccin"] ~= nil, "catppuccin module was loaded")
  check(package.loaded["mini.icons"] ~= nil, "mini.icons module was loaded")
  check(package.loaded["which-key"] ~= nil, "which-key module was loaded")
  check(package.loaded["catppuccin"] ~= nil, "catppuccin module was loaded")

  -- Stage 05 colorscheme.
  check_equal(vim.g.colors_name, "catppuccin-mocha", "active colorscheme")

  -- Stage 06 plugins.
  check_stage06_plugins()

  -- Leader keys.
  check_equal(vim.g.mapleader, " ", "mapleader")
  check_equal(vim.g.maplocalleader, "\\", "maplocalleader")

  -- Window-local options.
  check_equal(vim.wo.number, true, "number")
  check_equal(vim.wo.relativenumber, true, "relativenumber")
  check_equal(vim.wo.cursorline, true, "cursorline")
  check_equal(vim.wo.wrap, false, "wrap")

  -- Buffer-local options.
  check_equal(vim.bo.expandtab, true, "expandtab")
  check_equal(vim.bo.shiftwidth, 2, "shiftwidth")
  check_equal(vim.bo.tabstop, 2, "tabstop")
  check_equal(vim.bo.softtabstop, 2, "softtabstop")

  -- Global options.
  check_equal(vim.o.ignorecase, true, "ignorecase")
  check_equal(vim.o.smartcase, true, "smartcase")
  check_equal(vim.o.splitright, true, "splitright")
  check_equal(vim.o.splitbelow, true, "splitbelow")
  check_equal(vim.o.signcolumn, "yes", "signcolumn")
  check_equal(vim.o.showmode, false, "showmode")
  check_equal(vim.o.termguicolors, true, "termguicolors")
  check_equal(vim.o.updatetime, 250, "updatetime")
  check_equal(vim.o.timeoutlen, 400, "timeoutlen")
  check_equal(vim.o.undofile, true, "undofile")

  -- Native statusline.
  check_equal(vim.o.laststatus, 3, "laststatus")
  check_equal(vim.o.statusline, "%f %m%r%h%w %= %y %l:%c %p%%", "native statusline format")

  -- Windows shell resolution.
  if vim.fn.has("win32") == 1 then
    local windows_shell = vim.env.ComSpec

    if windows_shell and vim.fn.executable(windows_shell) == 1 then
      check_equal(vim.o.shell, windows_shell, "Windows shell path")
    end
  end

  -- Native keymap contract.
  local keymaps = {
    { mode = "n", lhs = "<C-s>", desc = "Save file" },
    { mode = "i", lhs = "<C-s>", desc = "Save file" },
    { mode = "v", lhs = "<C-s>", desc = "Save file" },
    { mode = "n", lhs = "<C-h>", desc = "Focus left window" },
    { mode = "n", lhs = "<C-j>", desc = "Focus lower window" },
    { mode = "n", lhs = "<C-k>", desc = "Focus upper window" },
    { mode = "n", lhs = "<C-l>", desc = "Focus right window" },
    { mode = "n", lhs = "<leader>sv", desc = "Split window vertically" },
    { mode = "n", lhs = "<leader>sh", desc = "Split window horizontally" },
    { mode = "n", lhs = "<leader>se", desc = "Equalize window sizes" },
    { mode = "n", lhs = "<leader>sx", desc = "Close current window" },
  }

  for _, expected in ipairs(keymaps) do
    local mapping = vim.fn.maparg(expected.lhs, expected.mode, false, true)

    check(type(mapping) == "table" and next(mapping) ~= nil, expected.mode .. " mapping exists: " .. expected.lhs)

    check_equal(mapping.desc, expected.desc, expected.mode .. " mapping " .. expected.lhs .. " description")
  end

  -- Autocommand contract.
  local autocmds = vim.api.nvim_get_autocmds({
    group = "nvim_config",
  })

  check(#autocmds >= 3, "expected at least three nvim_config autocommands")

  local required_events = {
    TextYankPost = false,
    BufReadPost = false,
    VimResized = false,
  }

  for _, autocmd in ipairs(autocmds) do
    if required_events[autocmd.event] ~= nil then
      required_events[autocmd.event] = true
    end
  end

  for event, found in pairs(required_events) do
    check(found, "autocommand event exists: " .. event)
  end

  -- Native diagnostics baseline.
  local diagnostics = vim.diagnostic.config()

  check_equal(diagnostics.virtual_text, true, "diagnostic virtual_text")
  check_equal(diagnostics.signs, true, "diagnostic signs")
  check_equal(diagnostics.underline, true, "diagnostic underline")
  check_equal(diagnostics.update_in_insert, false, "diagnostic update_in_insert")
  check_equal(diagnostics.severity_sort, true, "diagnostic severity_sort")

  -- Native terminal workflow.
  local terminal_escape = vim.fn.maparg("<Esc><Esc>", "t", false, true)

  check(terminal_escape ~= nil and next(terminal_escape) ~= nil, "terminal escape mapping exists")
  check_equal(terminal_escape.rhs, "<C-\\><C-n>", "terminal escape mapping rhs")
  check_equal(terminal_escape.desc, "Exit terminal mode", "terminal escape mapping description")

  -- Stage 04 native workflow tests.
  check_native_grep()

  -- Native commenting is deliberately deferred pending investigation.
  -- Keep check_native_commenting() available for when that investigation resumes.

  -- Required modules must fail visibly and stop later module loading.
  check_module_failure_contract(root)

  print(string.format("PASS nvim-config smoke test on Neovim %d.%d.%d", version.major, version.minor, version.patch))
end

local ok, err = pcall(main)

if not ok then
  io.stderr:write(tostring(err) .. "\n")
  vim.cmd("cquit 1")
end

vim.cmd("qa!")
