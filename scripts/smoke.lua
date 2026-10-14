-- Usage:
-- nvim --headless -u init.lua -c "luafile scripts/smoke.lua"

local function fail(message)
  io.stderr:write("FAIL nvim-config Stage 04: " .. message .. "\n")
  vim.cmd("cquit 1")
end

local function check(condition, message)
  if not condition then
    fail(message)
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

  -- This marker must never be printed because options fails first.
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

  -- Every result must contain a usable location and matching text.
  for _, item in ipairs(quickfix) do
    check(item.valid == 1, "native grep produces valid quickfix entries")
    check(item.lnum > 0, "quickfix result contains a valid line number")
    check(item.col > 0, "quickfix result contains a valid column")
    check(item.text ~= "", "quickfix result contains matching text")
  end

  print("PASS native grep and quickfix")
end

local function main()
  local root = vim.fn.getcwd()
  local version = vim.version()

  check(version.major > 0 or version.minor >= 12, "Neovim 0.12 or newer is required")

  -- Required configuration modules must have loaded.
  check(package.loaded["config.options"] ~= nil, "config.options was loaded")
  check(package.loaded["config.keymaps"] ~= nil, "config.keymaps was loaded")
  check(package.loaded["config.autocmds"] ~= nil, "config.autocmds was loaded")

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

  -- Native search and quickfix contract.
  check_native_grep()

  -- Verify required-module failures are visible and stop later loading.
  check_module_failure_contract(root)

  print(string.format("PASS nvim-config Stage 04 smoke test on Neovim %d.%d.%d", version.major, version.minor, version.patch))
end

local ok, err = pcall(main)

if not ok then
  io.stderr:write("FAIL nvim-config Stage 04: " .. tostring(err) .. "\n")
  vim.cmd("cquit 1")
end

vim.cmd("qa!")
