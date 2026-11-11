-- Native Neovim keymaps.
-- Keep mappings centralized and describe them for discoverability.
-- Add workflow mappings only after their implementation and validation.

local M = {}
local map = vim.keymap.set

-- ============================================================
-- Window Navigation
-- ============================================================

map("n", "<C-h>", "<C-w>h", {
  desc = "Focus left window",
})

map("n", "<C-j>", "<C-w>j", {
  desc = "Focus lower window",
})

map("n", "<C-k>", "<C-w>k", {
  desc = "Focus upper window",
})

map("n", "<C-l>", "<C-w>l", {
  desc = "Focus right window",
})

-- ============================================================
-- Window Resizing
-- ============================================================

map("n", "<C-Up>", "<cmd>resize -2<CR>", {
  desc = "Decrease window height",
})

map("n", "<C-Down>", "<cmd>resize +2<CR>", {
  desc = "Increase window height",
})

map("n", "<C-Left>", "<cmd>vertical resize -2<CR>", {
  desc = "Decrease window width",
})

map("n", "<C-Right>", "<cmd>vertical resize +2<CR>", {
  desc = "Increase window width",
})

-- ============================================================
-- File Operations
-- ============================================================

map({ "n", "i", "v" }, "<C-s>", "<cmd>write<CR>", {
  desc = "Save file",
})

-- ============================================================
-- Window Management
-- ============================================================

map("n", "<leader>sv", "<cmd>vsplit<CR>", {
  desc = "Split window vertically",
})

map("n", "<leader>sh", "<cmd>split<CR>", {
  desc = "Split window horizontally",
})

map("n", "<leader>se", "<C-w>=", {
  desc = "Equalize window sizes",
})

map("n", "<leader>sx", "<cmd>close<CR>", {
  desc = "Close current window",
})

-- ============================================================
-- Terminal
-- ============================================================

-- Open a terminal in a bottom split.
map("n", "<leader>tt", "<cmd>botright 12split | terminal<CR>", {
  desc = "Open terminal",
})

map("n", "<leader>tv", "<cmd>vertical split | terminal<CR>", {
  desc = "Open vertical terminal",
})

map("n", "<leader>th", "<cmd>split | terminal<CR>", {
  desc = "Open horizontal terminal",
})

map("t", "<Esc>", "<C-\\><C-n>", {
  desc = "Exit terminal mode",
})

-- Navigate between windows directly from terminal mode.
map("t", "<A-h>", "<C-\\><C-n><C-w>h", {
  desc = "Focus left window",
})

map("t", "<A-j>", "<C-\\><C-n><C-w>j", {
  desc = "Focus lower window",
})

map("t", "<A-k>", "<C-\\><C-n><C-w>k", {
  desc = "Focus upper window",
})

map("t", "<A-l>", "<C-\\><C-n><C-w>l", {
  desc = "Focus right window",
})

map("n", "<leader>tq", function()
  if vim.bo.buftype ~= "terminal" then
    vim.notify("Current buffer is not a terminal", vim.log.levels.WARN)
    return
  end

  vim.cmd("close")
end, {
  desc = "Close terminal window",
})

-- ============================================================
-- Buffer Navigation
-- ============================================================

map("n", "<leader>bd", "<cmd>bdelete<CR>", {
  desc = "Close buffer",
})

map("n", "<S-h>", "<cmd>bprevious<CR>", {
  desc = "Previous buffer",
})

map("n", "<S-l>", "<cmd>bnext<CR>", {
  desc = "Next buffer",
})

-- ============================================================
-- Tab Navigation
-- ============================================================

for i = 1, 5 do
  map("n", "<leader>" .. i, i .. "gt", {
    desc = "Go to tab " .. i,
  })
end

map("n", "<leader>tn", "<cmd>tabnew<CR>", {
  desc = "New tab",
})

map("n", "<leader>tc", "<cmd>tabclose<CR>", {
  desc = "Close tab",
})

-- ============================================================
-- Search
-- ============================================================

map("n", "<Esc>", "<cmd>nohlsearch<CR>", {
  desc = "Clear search highlights",
})

map("n", "<leader>nh", "<cmd>nohlsearch<CR>", {
  desc = "Clear search highlights",
})

-- ============================================================
-- Navigation Extras
-- ============================================================

-- Navigate by display line when wrapping is enabled.
-- Preserve normal line-count behavior.
map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", {
  expr = true,
  desc = "Move down (wrapped-line aware)",
})

map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", {
  expr = true,
  desc = "Move up (wrapped-line aware)",
})

-- Keep the cursor centered during scrolling and searching.
map("n", "<C-d>", "<C-d>zz", {
  desc = "Scroll down (centered)",
})

map("n", "<C-u>", "<C-u>zz", {
  desc = "Scroll up (centered)",
})

map("n", "n", "nzzzv", {
  desc = "Next match (centered)",
})

map("n", "N", "Nzzzv", {
  desc = "Previous match (centered)",
})

-- ============================================================
-- Editing
-- ============================================================

map("i", "jk", "<Esc>", {
  desc = "Exit insert mode",
})

map("x", "p", '"_dP', {
  desc = "Paste without overwriting clipboard",
})

map("x", "<", "<gv", {
  desc = "Dedent and stay in visual mode",
})

map("x", ">", ">gv", {
  desc = "Indent and stay in visual mode",
})

map("n", "<leader>e", "$", {
  desc = "Jump to end of line",
})

-- ============================================================
-- Formatting
-- ============================================================

-- Formatting remains manual.
map("n", "<leader>cf", "<cmd>Format<CR>", {
  desc = "Format buffer",
})

-- ============================================================
-- Search and Replace
-- ============================================================

-- Reuse the previous search pattern.
-- Review the replacement before executing.
map("n", "<leader>rs", ":%s/<C-r>//g<Left><Left>", {
  desc = "Replace previous search in buffer",
})

-- ============================================================
-- Line Movement
-- ============================================================

map("n", "<A-j>", "<cmd>m .+1<CR>==", {
  desc = "Move line down",
})

map("n", "<A-k>", "<cmd>m .-2<CR>==", {
  desc = "Move line up",
})

map("x", "<A-j>", ":m '>+1<CR>gv=gv", {
  desc = "Move selection down",
})

map("x", "<A-k>", ":m '<-2<CR>gv=gv", {
  desc = "Move selection up",
})

-- ============================================================
-- Diagnostics
-- ============================================================

map("n", "<leader>cd", vim.diagnostic.open_float, {
  desc = "Show line diagnostics",
})

map("n", "<leader>cq", function()
  vim.diagnostic.setqflist()
end, {
  desc = "Diagnostics to quickfix",
})

-- ============================================================
-- LSP
-- ============================================================

-- Register buffer-local mappings when an LSP client attaches.
function M.lsp(bufnr)
  local function lmap(mode, lhs, rhs, desc)
    map(mode, lhs, rhs, {
      buffer = bufnr,
      desc = "LSP: " .. desc,
    })
  end

  lmap("n", "gd", vim.lsp.buf.definition, "Go to definition")

  lmap("n", "gD", vim.lsp.buf.declaration, "Go to declaration")

  lmap({ "n", "i" }, "<leader>ck", vim.lsp.buf.signature_help, "Signature help")
end

-- ============================================================
-- Git
-- ============================================================

-- Register buffer-local mappings when Gitsigns attaches.
function M.gitsigns(bufnr)
  local gs = require("gitsigns")

  local function git_map(lhs, callback, description)
    map("n", lhs, callback, {
      buffer = bufnr,
      desc = "Git: " .. description,
    })
  end

  -- Hunk operations
  git_map("<leader>ghs", gs.stage_hunk, "Stage hunk")
  git_map("<leader>ghr", gs.reset_hunk, "Reset hunk")
  git_map("<leader>ghp", gs.preview_hunk, "Preview hunk")
  git_map("<leader>ghb", function()
    gs.blame_line({ full = true })
  end, "Blame line")

  -- Buffer operations
  git_map("<leader>ghS", gs.stage_buffer, "Stage buffer")
  git_map("<leader>ghR", gs.reset_buffer, "Reset buffer")
  git_map("<leader>ghd", gs.diffthis, "Diff buffer")

  -- Git visualization
  git_map("<leader>gb", gs.toggle_current_line_blame, "Toggle line blame")
  git_map("<leader>gw", gs.toggle_word_diff, "Toggle word diff")
end

-- ============================================================
-- Sessions
-- ============================================================

-- Load Mini Sessions only when a session command is invoked.
map("n", "<leader>qs", function()
  require("mini.sessions").select("read")
end, {
  desc = "Session: Restore",
})

map("n", "<leader>qw", function()
  require("mini.sessions").select("write")
end, {
  desc = "Session: Save",
})

map("n", "<leader>qd", function()
  require("mini.sessions").select("delete")
end, {
  desc = "Session: Delete",
})

-- ============================================================
-- Data Tools
-- ============================================================

map("n", "<leader>jq", function()
  require("langs.data").run_prompt()
end, {
  desc = "Run jq filter",
})

-- ============================================================
-- Central LSP operations.
-- ============================================================

map("n", "<leader>rn", vim.lsp.buf.rename, {
  desc = "LSP: Rename symbol",
})

map("n", "<leader>ca", vim.lsp.buf.code_action, {
  desc = "LSP: Code actions",
})

-- ============================================================
-- Shell
-- ============================================================

map("n", "<leader>cw", "<cmd>ShellcheckWiki<CR>", {
  desc = "Open ShellCheck wiki",
})

-- ============================================================
-- Lua
-- ============================================================

local function lua_project_root(bufnr)
  local root = vim.fs.root(bufnr, {
    ".busted",
    ".git",
    "spec",
  })

  if root then
    return root
  end

  local name = vim.api.nvim_buf_get_name(bufnr)

  return name ~= "" and vim.fs.dirname(name) or vim.fn.getcwd()
end

local function run_lua_buffer(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local source = table.concat(lines, "\n")
  local name = vim.api.nvim_buf_get_name(bufnr)
  local chunk, err = load(source, "@" .. (name ~= "" and name or "lua-buffer"))

  if not chunk then
    vim.notify(err, vim.log.levels.ERROR, {
      title = "Lua buffer",
    })
    return
  end

  local ok, result = pcall(chunk)

  if not ok then
    vim.notify(result, vim.log.levels.ERROR, {
      title = "Lua buffer",
    })
    return
  end

  vim.notify("Executed current Lua buffer", vim.log.levels.INFO, {
    title = "Lua buffer",
  })
end

local function run_lua_tests(bufnr)
  if vim.fn.executable("busted") ~= 1 then
    vim.notify("Busted is unavailable. Install it with: luarocks install busted", vim.log.levels.WARN, { title = "Lua tests" })
    return
  end

  local root = lua_project_root(bufnr)

  vim.cmd("botright 12new")

  local output_buf = vim.api.nvim_get_current_buf()

  vim.bo[output_buf].buftype = "nofile"
  vim.bo[output_buf].bufhidden = "wipe"
  vim.bo[output_buf].swapfile = false
  vim.bo[output_buf].filetype = "text"

  vim.api.nvim_buf_set_lines(output_buf, 0, -1, false, {
    "Running Busted...",
    "Project: " .. root,
    "",
  })

  local function show_output(lines)
    vim.schedule(function()
      if not vim.api.nvim_buf_is_valid(output_buf) then
        return
      end

      vim.bo[output_buf].modifiable = true
      vim.api.nvim_buf_set_lines(output_buf, 0, -1, false, lines)
      vim.bo[output_buf].modifiable = false
    end)
  end

  local ok, process = pcall(vim.system, { "busted" }, {
    cwd = root,
    text = true,
  }, function(result)
    local lines = {}

    local stdout = vim.split(result.stdout or "", "\n", {
      trimempty = true,
    })

    local stderr = vim.split(result.stderr or "", "\n", {
      trimempty = true,
    })

    vim.list_extend(lines, stdout)

    if #stderr > 0 then
      if #lines > 0 then
        table.insert(lines, "")
      end

      table.insert(lines, "Standard error:")
      vim.list_extend(lines, stderr)
    end

    if #lines == 0 then
      table.insert(lines, "Busted produced no output.")
    end

    table.insert(lines, "")
    table.insert(lines, string.format("Busted exited with code %d", result.code))

    show_output(lines)

    vim.schedule(function()
      if result.code == 0 then
        vim.notify("Lua tests passed", vim.log.levels.INFO, {
          title = "Busted",
        })
      else
        vim.notify(string.format("Lua tests failed (exit code %d)", result.code), vim.log.levels.ERROR, { title = "Busted" })
      end
    end)
  end)

  if not ok then
    show_output({
      "Failed to start Busted:",
      tostring(process),
    })

    vim.notify("Failed to start Busted", vim.log.levels.ERROR, {
      title = "Lua tests",
    })
  end
end

function M.lua(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  map("n", "<leader>cr", "<cmd>luafile %<cr>", {
    buffer = bufnr,
    desc = "Run Lua file",
  })

  map("n", "<leader>cb", function()
    run_lua_buffer(bufnr)
  end, {
    buffer = bufnr,
    desc = "Run Lua buffer",
  })

  map("n", "<leader>ct", function()
    run_lua_tests(bufnr)
  end, {
    buffer = bufnr,
    desc = "Run Lua tests",
  })
end

-- ============================================================
-- Python
-- ============================================================

local python_root_markers = {
  "pyproject.toml",
  "pytest.ini",
  "tox.ini",
  "setup.cfg",
  "setup.py",
  "requirements.txt",
  "Pipfile",
  "uv.lock",
  "poetry.lock",
  ".git",
}

local function python_root(bufnr)
  local root = vim.fs.root(bufnr, python_root_markers)

  if root then
    return root
  end

  local filename = vim.api.nvim_buf_get_name(bufnr)

  return vim.fn.fnamemodify(filename, ":p:h")
end

local function python_interpreter(root)
  local is_windows = vim.fn.has("win32") == 1
  local python_relative_path = is_windows and { ".venv", "Scripts", "python.exe" } or { ".venv", "bin", "python" }

  -- Prefer the project's virtual environment.
  local project_python = vim.fs.joinpath(root, unpack(python_relative_path))

  if vim.fn.executable(project_python) == 1 then
    return project_python, "project"
  end

  -- Fall back to the virtual environment active when Neovim started.
  local active_venv = vim.env.VIRTUAL_ENV

  if active_venv and active_venv ~= "" then
    local active_python = is_windows and vim.fs.joinpath(active_venv, "Scripts", "python.exe") or vim.fs.joinpath(active_venv, "bin", "python")

    if vim.fn.executable(active_python) == 1 then
      return active_python, "active"
    end
  end

  -- Use the system Python executable as the final fallback.
  local system_python = is_windows and "python" or "python3"
  local executable = vim.fn.exepath(system_python)

  if executable ~= "" then
    return executable, "system"
  end

  return nil
end

local function python_terminal(command, root)
  vim.cmd("botright 12new")

  local ok, job = pcall(vim.fn.jobstart, command, {
    cwd = root,
    term = true,
  })

  if not ok or job <= 0 then
    vim.cmd("close")
    vim.notify("Failed to start Python workflow", vim.log.levels.ERROR)
    return
  end

  vim.cmd("startinsert")
end

local function python_tool(name, args, root)
  local executable = vim.fn.exepath(name)

  if executable == "" then
    vim.notify(name .. " is not installed or not available on PATH", vim.log.levels.ERROR)
    return
  end

  local command = { executable }
  vim.list_extend(command, args)

  python_terminal(command, root)
end

-- Register buffer-local Python workflow mappings.
function M.python(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  local function python_map(lhs, callback, description)
    map("n", lhs, callback, {
      buffer = bufnr,
      desc = "Python: " .. description,
    })
  end

  local function get_context()
    local filename = vim.api.nvim_buf_get_name(bufnr)

    if filename == "" then
      vim.notify("Python workflow requires a saved file", vim.log.levels.WARN)
      return
    end

    return filename, python_root(bufnr)
  end

  local function run_python(args)
    local filename, root = get_context()

    if not filename then
      return
    end

    local interpreter, source = python_interpreter(root)

    if not interpreter then
      vim.notify("Python interpreter not found. Check the project .venv or system PATH.", vim.log.levels.ERROR)
      return
    end

    if source == "system" then
      vim.notify("Project and active virtual environments were not found; using system Python", vim.log.levels.INFO)
    end

    local command = { interpreter }
    vim.list_extend(command, args)

    python_terminal(command, root)
  end

  -- Run the current Python file.
  python_map("<leader>cr", function()
    local filename = vim.api.nvim_buf_get_name(bufnr)

    if filename == "" then
      vim.notify("Python workflow requires a saved file", vim.log.levels.WARN)
      return
    end

    run_python({ vim.fn.fnamemodify(filename, ":p") })
  end, "Run file")

  -- Run the project's pytest suite.
  python_map("<leader>ct", function()
    run_python({ "-m", "pytest" })
  end, "Run tests")

  -- Run project type checking with ty.
  python_map("<leader>cc", function()
    local _, root = get_context()

    if not root then
      return
    end

    python_tool("ty", { "check", "." }, root)
  end, "Type check")

  -- Lint the current Python file with Ruff.
  python_map("<leader>cl", function()
    local filename = vim.api.nvim_buf_get_name(bufnr)

    if filename == "" then
      vim.notify("Python workflow requires a saved file", vim.log.levels.WARN)
      return
    end

    local root = python_root(bufnr)

    python_tool("ruff", { "check", vim.fn.fnamemodify(filename, ":p") }, root)
  end, "Lint file")
end

-- ============================================================
-- Rust
-- ============================================================

-- Register buffer-local Cargo workflow mappings.
function M.rust(bufnr)
  local function rust_map(lhs, command, description)
    map("n", lhs, command, {
      buffer = bufnr,
      desc = "Rust: " .. description,
    })
  end

  rust_map("<leader>cr", "<cmd>Cargo run<CR>", "Run project")
  rust_map("<leader>cb", "<cmd>Cargo build<CR>", "Build project")
  rust_map("<leader>ct", "<cmd>Cargo test<CR>", "Run tests")
  rust_map("<leader>cc", "<cmd>Cargo check<CR>", "Check project")
end

-- ============================================================
-- C and C++
-- ============================================================

local function switch_source_header(bufnr)
  local method = "textDocument/switchSourceHeader"
  local win = vim.api.nvim_get_current_win()
  local clients = vim.lsp.get_clients({
    bufnr = bufnr,
    name = "clangd",
  })

  if #clients == 0 then
    return vim.notify("clangd is not attached to this buffer", vim.log.levels.WARN)
  end

  local client = clients[1]

  -- Keep this check defensive; clangd's request result remains authoritative.
  if not client:supports_method(method, bufnr) then
    return vim.notify("clangd does not support source/header switching", vim.log.levels.WARN)
  end

  local params = {
    uri = vim.uri_from_bufnr(bufnr),
  }

  local sent = client:request(method, params, function(err, result)
    if err then
      return vim.notify("clangd source/header switch failed: " .. err.message, vim.log.levels.ERROR)
    end

    if not result then
      return vim.notify("No matching source/header file found", vim.log.levels.INFO)
    end

    if not vim.api.nvim_buf_is_valid(bufnr) then
      return vim.notify("Original buffer is no longer valid", vim.log.levels.WARN)
    end

    if not vim.api.nvim_win_is_valid(win) then
      return vim.notify("Original window is no longer valid", vim.log.levels.WARN)
    end

    if vim.api.nvim_win_get_buf(win) ~= bufnr then
      return vim.notify("Original buffer is no longer displayed in its window", vim.log.levels.WARN)
    end

    local filename = vim.uri_to_fname(result)

    vim.api.nvim_win_call(win, function()
      vim.cmd.edit(vim.fn.fnameescape(filename))
    end)
  end, bufnr)

  if not sent then
    return vim.notify("clangd rejected the source/header switch request", vim.log.levels.WARN)
  end
end

-- Register buffer-local CMake and clangd workflow mappings.
function M.c_cpp(bufnr)
  local function c_cpp_map(lhs, command, description)
    map("n", lhs, command, {
      buffer = bufnr,
      desc = "C/C++: " .. description,
    })
  end

  c_cpp_map("<leader>cb", "<cmd>CMakeBuild<CR>", "Build project")
  c_cpp_map("<leader>cr", "<cmd>CMakeRun<CR>", "Run executable")

  c_cpp_map("<leader>ch", function()
    switch_source_header(bufnr)
  end, "Switch source/header")
end

-- ============================================================
-- Markdown
-- ============================================================

-- Preview
vim.keymap.set("n", "<leader>mp", "<Plug>(md-render-preview)", {
  desc = "Markdown preview (toggle)",
})

vim.keymap.set("n", "<leader>mt", "<Plug>(md-render-preview-tab)", {
  desc = "Markdown preview in tab (toggle)",
})

vim.keymap.set("n", "<leader>md", "<Plug>(md-render-demo)", {
  desc = "Markdown render demo",
})

-- Linting
vim.keymap.set("n", "<leader>ml", "<cmd>MarkdownLint<cr>", {
  desc = "Markdown lint",
})

-- Table of contents
vim.keymap.set("n", "<leader>mo", "<cmd>MarkdownToc<cr>", {
  desc = "Markdown update table of contents",
})

-- Diagnostics
vim.keymap.set("n", "<leader>mc", function()
  vim.diagnostic.reset(nil, 0)
end, {
  desc = "Clear Markdown diagnostics",
})

return M
