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

--- ============================================================
-- Go
-- ============================================================

local function go_notify(message, level)
  vim.notify(message, level, {
    title = "Go",
  })
end

-- Create a dedicated scratch buffer for command output.
local function go_output_buffer(command, cwd, workspace)
  vim.cmd("botright 12new")

  local bufnr = vim.api.nvim_get_current_buf()

  vim.bo[bufnr].buftype = "nofile"
  vim.bo[bufnr].bufhidden = "wipe"
  vim.bo[bufnr].swapfile = false
  vim.bo[bufnr].filetype = "text"

  local lines = {
    "Command: " .. vim.inspect(command),
    "Directory: " .. cwd,
  }

  if workspace then
    table.insert(lines, "Go workspace: " .. workspace)
  end

  table.insert(lines, "")
  table.insert(lines, "Running...")

  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.bo[bufnr].modifiable = false

  return bufnr
end

-- Update the output buffer if it still exists.
local function go_set_output(bufnr, lines)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  vim.bo[bufnr].modifiable = true
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.bo[bufnr].modifiable = false
end

-- Execute a Go workflow asynchronously.
local function go_run_command(command, cwd, workspace)
  local output_buf = go_output_buffer(command, cwd, workspace)

  local ok, process = pcall(
    vim.system,
    command,
    {
      cwd = cwd,
      text = true,
    },
    vim.schedule_wrap(function(result)
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
        table.insert(lines, "Process produced no output.")
      end

      table.insert(lines, "")

      if result.signal and result.signal ~= 0 then
        table.insert(lines, "Signal: " .. tostring(result.signal))
      end

      table.insert(lines, "Exit code: " .. tostring(result.code))

      go_set_output(output_buf, lines)

      if result.code == 0 then
        go_notify("Command completed successfully", vim.log.levels.INFO)
      else
        go_notify("Command failed with exit code " .. tostring(result.code), vim.log.levels.ERROR)
      end
    end)
  )

  if not ok then
    go_set_output(output_buf, {
      "Failed to start command:",
      tostring(process),
    })

    go_notify("Failed to start command", vim.log.levels.ERROR)
  end
end

-- Resolve module context from the current Go source file.
--
-- GOMOD identifies the module containing the current package.
-- GOWORK identifies the active workspace, when configured.
local function go_resolve_context(bufnr, callback)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  local filename = vim.api.nvim_buf_get_name(bufnr)

  if filename == "" then
    go_notify("Save the Go file before running this workflow", vim.log.levels.WARN)
    return
  end

  local package_dir = vim.fs.dirname(filename)
  local executable = vim.fn.exepath("go")

  if executable == "" then
    go_notify("Go toolchain is unavailable on PATH", vim.log.levels.ERROR)
    return
  end

  local ok, process = pcall(
    vim.system,
    {
      executable,
      "env",
      "GOMOD",
      "GOWORK",
    },
    {
      cwd = package_dir,
      text = true,
    },
    vim.schedule_wrap(function(result)
      -- Ignore stale results if the original buffer changed.
      if not vim.api.nvim_buf_is_valid(bufnr) then
        return
      end

      if vim.api.nvim_buf_get_name(bufnr) ~= filename then
        return
      end

      if result.code ~= 0 then
        go_notify("Could not resolve Go module context: " .. vim.trim(result.stderr or ""), vim.log.levels.ERROR)
        return
      end

      local lines = vim.split(result.stdout or "", "\n", {
        plain = true,
        trimempty = false,
      })

      local gomod = vim.trim(lines[1] or "")
      local gowork = vim.trim(lines[2] or "")

      if gomod == "" or gomod == "/dev/null" or gomod == "NUL" then
        go_notify("The current file is not inside a Go module", vim.log.levels.WARN)
        return
      end

      gomod = vim.fs.normalize(gomod)

      local stat = vim.uv.fs_stat(gomod)

      if not stat or stat.type ~= "file" then
        go_notify("Go returned an invalid module file path: " .. gomod, vim.log.levels.ERROR)
        return
      end

      local workspace

      if gowork ~= "" and gowork ~= "off" then
        workspace = vim.fs.normalize(gowork)
      end

      callback({
        go = executable,
        package_dir = package_dir,
        module_root = vim.fs.dirname(gomod),
        workspace = workspace,
      })
    end)
  )

  if not ok then
    go_notify("Could not start Go module detection: " .. tostring(process), vim.log.levels.ERROR)
  end
end

-- Register buffer-local Go workflow mappings.
function M.go(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  local function go_map(lhs, callback, description)
    map("n", lhs, callback, {
      buffer = bufnr,
      desc = "Go: " .. description,
    })
  end

  -- Resolve the module context before executing a Go command.
  local function run_go(args, directory)
    go_resolve_context(bufnr, function(context)
      local command = { context.go }
      vim.list_extend(command, args)

      go_run_command(command, directory(context), context.workspace)
    end)
  end

  -- Run the package containing the current file.
  go_map("<leader>cr", function()
    run_go({ "run", "." }, function(context)
      return context.package_dir
    end)
  end, "Run package")

  -- Build every package in the current module.
  go_map("<leader>cb", function()
    run_go({ "build", "./..." }, function(context)
      return context.module_root
    end)
  end, "Build module")

  -- Run tests in the current module.
  go_map("<leader>ct", function()
    run_go({ "test", "./..." }, function(context)
      return context.module_root
    end)
  end, "Run module tests")

  -- Run golangci-lint without applying automatic fixes.
  go_map("<leader>cl", function()
    local executable = vim.fn.exepath("golangci-lint")

    if executable == "" then
      go_notify("golangci-lint is unavailable on PATH", vim.log.levels.ERROR)
      return
    end

    go_resolve_context(bufnr, function(context)
      go_run_command({
        executable,
        "run",
        "./...",
      }, context.module_root, context.workspace)
    end)
  end, "Lint module")

  -- Run Go's static analysis checks independently of golangci-lint.
  go_map("<leader>cc", function()
    run_go({ "vet", "./..." }, function(context)
      return context.module_root
    end)
  end, "Vet module")
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

-- Register buffer-local Markdown workflow mappings.
function M.markdown(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  local function markdown_map(lhs, rhs, description)
    map("n", lhs, rhs, {
      buffer = bufnr,
      desc = "Markdown: " .. description,
    })
  end

  -- Preview
  markdown_map("<leader>mp", "<Plug>(md-render-preview)", "Toggle preview")

  markdown_map("<leader>mt", "<Plug>(md-render-preview-tab)", "Toggle preview in tab")

  markdown_map("<leader>md", "<Plug>(md-render-demo)", "Open rendering demo")

  -- Linting
  markdown_map("<leader>ml", "<cmd>MarkdownLint<CR>", "Lint buffer")

  -- Table of contents
  markdown_map("<leader>mo", "<cmd>MarkdownToc<CR>", "Update table of contents")

  -- Diagnostics
  markdown_map("<leader>mc", function()
    vim.diagnostic.reset(nil, bufnr)
  end, "Clear buffer diagnostics")

  -- Mermaid diagrams
  markdown_map("<leader>mr", "<cmd>MermaidRender<CR>", "Render Mermaid diagram")
end

-- ============================================================
-- JavaScript and TypeScript
-- ============================================================

local package_manager_lockfiles = {
  npm = { "package-lock.json", "npm-shrinkwrap.json" },
  pnpm = { "pnpm-lock.yaml" },
  yarn = { "yarn.lock" },
  bun = { "bun.lock", "bun.lockb" },
}

local allowed_javascript_scripts = {
  dev = true,
  start = true,
  test = true,
  build = true,
  lint = true,
  typecheck = true,
  check = true,
}

local function javascript_notify(message, level)
  vim.notify(message, level or vim.log.levels.INFO, {
    title = "JavaScript / TypeScript",
  })
end

local function javascript_is_file(path)
  return vim.uv.fs_stat(path) ~= nil
end

local function javascript_read_package(package_file)
  local ok, lines = pcall(vim.fn.readfile, package_file)

  if not ok or type(lines) ~= "table" then
    return nil, "Could not read " .. package_file
  end

  local decoded, package_json = pcall(vim.json.decode, table.concat(lines, "\n"))

  if not decoded or type(package_json) ~= "table" then
    return nil, "Could not parse " .. package_file
  end

  return package_json
end

local function javascript_dependencies(package_json)
  local dependencies = {}

  for _, field in ipairs({
    "dependencies",
    "devDependencies",
    "optionalDependencies",
  }) do
    local entries = package_json[field]

    if type(entries) == "table" then
      for name, version in pairs(entries) do
        if type(name) == "string" and version ~= nil then
          dependencies[name] = true
        end
      end
    end
  end

  return dependencies
end

-- Framework detection is package-local.
-- Do not infer frameworks from filenames or sibling packages.
local function javascript_frameworks(package_json)
  local dependencies = javascript_dependencies(package_json)

  local expo = dependencies.expo == true
  local react_native_dependency = dependencies["react-native"] == true

  return {
    expo = expo,
    react_native = react_native_dependency and not expo,
    react_native_dependency = react_native_dependency,
    nextjs = dependencies.next == true,
  }
end

local function javascript_has_workspace_marker(directory, package_json)
  if type(package_json.workspaces) == "table" or type(package_json.workspaces) == "string" then
    return true
  end

  return javascript_is_file(vim.fs.joinpath(directory, "pnpm-workspace.yaml"))
end

-- Find the nearest workspace root above the package root.
-- npm, pnpm, Yarn, and Bun workspace metadata is resolved here.
local function javascript_workspace_context(package_root, package_json)
  local directory = package_root

  while directory do
    local package_file = vim.fs.joinpath(directory, "package.json")
    local workspace_package = {}

    if javascript_is_file(package_file) then
      local parsed, err = javascript_read_package(package_file)

      if not parsed then
        return nil, err
      end

      workspace_package = parsed
    end

    if javascript_has_workspace_marker(directory, workspace_package) then
      return {
        root = directory,
        package_file = javascript_is_file(package_file) and package_file or nil,
        package = workspace_package,
      }
    end

    local parent = vim.fs.dirname(directory)

    if parent == directory then
      break
    end

    directory = parent
  end

  -- A standalone package is its own package-manager root.
  return {
    root = package_root,
    package_file = vim.fs.joinpath(package_root, "package.json"),
    package = package_json,
  }
end

-- Resolve the nearest package.json from the current buffer.
local function javascript_package_context(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    javascript_notify("The source buffer is no longer valid", vim.log.levels.ERROR)
    return
  end

  local filename = vim.api.nvim_buf_get_name(bufnr)

  if filename == "" then
    javascript_notify("Save the source file before running a workflow", vim.log.levels.WARN)
    return
  end

  local absolute_filename = vim.fn.fnamemodify(filename, ":p")

  local package_files = vim.fs.find("package.json", {
    path = vim.fs.dirname(absolute_filename),
    upward = true,
    type = "file",
  })

  local package_file = package_files[1]

  if not package_file then
    javascript_notify("No package.json was found in the parent directories", vim.log.levels.WARN)
    return
  end

  local package_json, err = javascript_read_package(package_file)

  if not package_json then
    javascript_notify(err, vim.log.levels.ERROR)
    return
  end

  local package_root = vim.fs.dirname(package_file)

  local workspace, workspace_err = javascript_workspace_context(package_root, package_json)

  if not workspace then
    javascript_notify(workspace_err, vim.log.levels.ERROR)
    return
  end

  return {
    root = package_root,
    package_file = package_file,
    package = package_json,

    frameworks = javascript_frameworks(package_json),

    workspace_root = workspace.root,
    workspace_package_file = workspace.package_file,
    workspace_package = workspace.package,
  }
end

local function javascript_parse_package_manager(value)
  if type(value) ~= "string" then
    return nil, "packageManager must be a string"
  end

  local manager = value:match("^([%w_-]+)@")

  if not manager or not package_manager_lockfiles[manager] then
    return nil, "Unsupported packageManager value: " .. value
  end

  return manager
end

-- Prefer explicit packageManager declarations.
-- Reject conflicting package/workspace declarations.
-- Otherwise inspect lockfiles at the workspace root.
local function javascript_package_manager(context)
  local package_value = context.package.packageManager
  local workspace_value = context.workspace_package.packageManager

  local package_manager
  local workspace_manager

  if package_value ~= nil then
    local err

    package_manager, err = javascript_parse_package_manager(package_value)

    if not package_manager then
      javascript_notify(err, vim.log.levels.ERROR)
      return
    end
  end

  if workspace_value ~= nil then
    local err

    workspace_manager, err = javascript_parse_package_manager(workspace_value)

    if not workspace_manager then
      javascript_notify(err, vim.log.levels.ERROR)
      return
    end
  end

  if package_manager and workspace_manager and package_manager ~= workspace_manager then
    javascript_notify(
      string.format("Conflicting packageManager declarations: package uses %s, workspace uses %s", package_manager, workspace_manager),
      vim.log.levels.ERROR
    )
    return
  end

  if package_manager or workspace_manager then
    return package_manager or workspace_manager
  end

  local detected = {}

  for manager, lockfiles in pairs(package_manager_lockfiles) do
    for _, lockfile in ipairs(lockfiles) do
      local path = vim.fs.joinpath(context.workspace_root, lockfile)

      if javascript_is_file(path) then
        detected[manager] = true
        break
      end
    end
  end

  local managers = vim.tbl_keys(detected)
  table.sort(managers)

  if #managers == 0 then
    javascript_notify("Package manager is unknown. Declare packageManager in package.json or commit a recognized lockfile.", vim.log.levels.WARN)
    return
  end

  if #managers > 1 then
    javascript_notify(
      "Conflicting package-manager lockfiles found: " .. table.concat(managers, ", ") .. ". Declare one packageManager in the workspace package.json.",
      vim.log.levels.ERROR
    )
    return
  end

  return managers[1]
end

-- Select the first existing, non-empty, approved script.
local function javascript_script(context, candidates)
  local scripts = context.package.scripts

  if type(scripts) ~= "table" then
    javascript_notify("package.json does not define any scripts", vim.log.levels.WARN)
    return
  end

  for _, name in ipairs(candidates) do
    if not allowed_javascript_scripts[name] then
      javascript_notify("Unsupported workflow script: " .. tostring(name), vim.log.levels.ERROR)
      return
    end

    local value = scripts[name]

    if type(value) == "string" and vim.trim(value) ~= "" then
      return name
    end
  end

  javascript_notify("No matching package script was found. Expected: " .. table.concat(candidates, " or "), vim.log.levels.WARN)
end

local function javascript_executable(manager)
  local executable = vim.fn.exepath(manager)

  if executable == "" then
    javascript_notify(manager .. " is not installed or not available on PATH", vim.log.levels.ERROR)
    return
  end

  return executable
end

local function javascript_command(executable, script)
  if vim.fn.has("win32") ~= 1 then
    return {
      executable,
      "run",
      script,
    }
  end

  -- Windows package managers commonly use .cmd shims.
  -- Script names are restricted by allowed_javascript_scripts.
  local command_processor = vim.env.COMSPEC

  if not command_processor or command_processor == "" then
    command_processor = "cmd.exe"
  end

  local command = '"' .. executable .. '" run ' .. script

  return {
    command_processor,
    "/d",
    "/s",
    "/c",
    '""' .. command .. '""',
  }
end

local function javascript_terminal(command, root)
  vim.cmd("botright 12new")

  local terminal_buffer = vim.api.nvim_get_current_buf()

  vim.bo[terminal_buffer].bufhidden = "hide"
  vim.bo[terminal_buffer].swapfile = false

  local ok, job = pcall(vim.fn.jobstart, command, {
    cwd = root,
    term = true,
  })

  if not ok or job <= 0 then
    vim.cmd("close")

    javascript_notify("Failed to start the package script", vim.log.levels.ERROR)
    return
  end

  vim.cmd("startinsert")
end

local function run_javascript_script(bufnr, candidates)
  local context = javascript_package_context(bufnr)

  if not context then
    return
  end

  local script = javascript_script(context, candidates)

  if not script then
    return
  end

  local manager = javascript_package_manager(context)

  if not manager then
    return
  end

  local executable = javascript_executable(manager)

  if not executable then
    return
  end

  local command = javascript_command(executable, script)

  javascript_notify(string.format("Running %s with %s in %s", script, manager, context.root), vim.log.levels.INFO)

  javascript_terminal(command, context.root)
end

-- ============================================================
-- Register buffer-local JavaScript and TypeScript workflows.
-- ============================================================

function M.javascript(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  local function javascript_map(lhs, candidates, description)
    map("n", lhs, function()
      run_javascript_script(bufnr, candidates)
    end, {
      buffer = bufnr,
      desc = "JavaScript: " .. description,
    })
  end

  javascript_map("<leader>cR", { "dev", "start" }, "Start development")
  javascript_map("<leader>ct", { "test" }, "Run tests")
  javascript_map("<leader>cb", { "build" }, "Build project")
  javascript_map("<leader>cl", { "lint" }, "Lint project")
  javascript_map("<leader>cc", { "typecheck", "check" }, "Type-check project")
end

return M
