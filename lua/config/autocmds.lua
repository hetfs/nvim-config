-- Native autocommands.
-- Neovim 0.12+

local api = vim.api

local group = api.nvim_create_augroup("nvim_config", {
  clear = true,
})

-- ============================================================
-- Helpers
-- ============================================================

---@param width integer
local function set_indentation(width)
  vim.opt_local.shiftwidth = width
  vim.opt_local.tabstop = width
  vim.opt_local.softtabstop = width
  vim.opt_local.expandtab = true
end

local function enable_treesitter_folding()
  vim.opt_local.foldmethod = "expr"
  vim.opt_local.foldexpr = "v:lua.vim.treesitter.foldexpr()"
end

-- ============================================================
-- Yank Highlighting
-- ============================================================

api.nvim_create_autocmd("TextYankPost", {
  group = group,
  desc = "Highlight yanked text",
  callback = function()
    vim.hl.on_yank({
      higroup = "IncSearch",
      timeout = 200,
    })
  end,
})

-- ============================================================
-- External File Changes
-- ============================================================

api.nvim_create_autocmd({
  "FocusGained",
  "TermClose",
  "TermLeave",
}, {
  group = group,
  desc = "Reload files changed outside Neovim",
  callback = function()
    if vim.bo.buftype == "" then
      vim.cmd.checktime()
    end
  end,
})

-- ============================================================
-- Cursor Position Restoration
-- ============================================================

api.nvim_create_autocmd("BufReadPost", {
  group = group,
  desc = "Restore previous cursor position",
  callback = function(event)
    local buf = event.buf

    -- Ignore special buffers.
    if vim.bo[buf].buftype ~= "" then
      return
    end

    local mark = api.nvim_buf_get_mark(buf, '"')
    local line_count = api.nvim_buf_line_count(buf)

    if mark[1] < 1 or mark[1] > line_count then
      return
    end

    -- Restore the cursor in a window displaying this buffer.
    for _, win in ipairs(vim.fn.win_findbuf(buf)) do
      if api.nvim_win_is_valid(win) then
        local line = mark[1]
        local col = mark[2]

        -- Clamp the column to the target line's length.
        local line_text = api.nvim_buf_get_lines(
          buf,
          line - 1,
          line,
          false
        )[1] or ""

        col = math.min(col, #line_text)

        pcall(api.nvim_win_set_cursor, win, { line, col })
        break
      end
    end
  end,
})

-- ============================================================
-- Window Management
-- ============================================================

api.nvim_create_autocmd("VimResized", {
  group = group,
  desc = "Rebalance windows after resize",
  callback = function()
    vim.cmd.tabdo("wincmd =")
  end,
})

-- ============================================================
-- Help and Utility Windows
-- ============================================================

api.nvim_create_autocmd("FileType", {
  group = group,
  desc = "Close help and utility windows with q",
  pattern = {
    "help",
    "qf",
    "man",
    "checkhealth",
  },
  callback = function(event)
    vim.bo[event.buf].buflisted = false

    vim.keymap.set("n", "q", "<cmd>close<CR>", {
      buffer = event.buf,
      silent = true,
      desc = "Close window",
    })
  end,
})

-- ============================================================
-- Writing and Prose
-- ============================================================

api.nvim_create_autocmd("FileType", {
  group = group,
  desc = "Configure prose buffers",
  pattern = {
    "markdown",
    "text",
    "gitcommit",
  },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.spell = true
  end,
})

-- ============================================================
-- Markdown
-- ============================================================

api.nvim_create_autocmd("FileType", {
  group = group,
  desc = "Configure Markdown buffers",
  pattern = "markdown",
  callback = function(event)
    -- Readable paragraph wrapping.
    vim.opt_local.linebreak = true
    vim.opt_local.breakindent = true

    -- Consistent Markdown indentation.
    set_indentation(2)

    -- Register Markdown workflow mappings.
    require("config.keymaps").markdown(event.buf)
  end,
})

-- ============================================================
-- Shell
-- ============================================================

api.nvim_create_autocmd("FileType", {
  group = group,
  desc = "Configure Shell buffers",
  pattern = {
    "sh",
    "bash",
  },
  callback = function()
    set_indentation(4)
    enable_treesitter_folding()
  end,
})

-- ============================================================
-- File Saving
-- ============================================================

api.nvim_create_autocmd("BufWritePre", {
  group = group,
  desc = "Create missing parent directories before saving",
  callback = function(event)
    local buf = event.buf

    -- Ignore special buffers.
    if vim.bo[buf].buftype ~= "" then
      return
    end

    local file = event.file

    -- Ignore empty filenames and URI-based buffers.
    if file == "" or file:match("^%a[%w+.-]*://") then
      return
    end

    local dir = vim.fn.fnamemodify(file, ":p:h")

    if vim.fn.isdirectory(dir) == 1 then
      return
    end

    local result = vim.fn.mkdir(dir, "p")

    if result == 0 and vim.fn.isdirectory(dir) == 0 then
      error("Failed to create parent directory: " .. dir)
    end
  end,
})

-- ============================================================
-- Lua
-- ============================================================

api.nvim_create_autocmd("FileType", {
  group = group,
  desc = "Configure Lua buffers",
  pattern = "lua",
  callback = function(event)
    require("config.keymaps").lua(event.buf)
  end,
})

-- ============================================================
-- C and C++
-- ============================================================

api.nvim_create_autocmd("FileType", {
  group = group,
  desc = "Configure C and C++ buffers",
  pattern = {
    "c",
    "cpp",
  },
  callback = function(event)
    require("config.keymaps").c_cpp(event.buf)
  end,
})

-- ============================================================
-- Python
-- ============================================================

api.nvim_create_autocmd("FileType", {
  group = group,
  desc = "Configure Python buffers",
  pattern = "python",
  callback = function(event)
    require("config.keymaps").python(event.buf)
  end,
})

-- ============================================================
-- Rust
-- ============================================================

api.nvim_create_autocmd("FileType", {
  group = group,
  desc = "Configure Rust buffers",
  pattern = "rust",
  callback = function(event)
    set_indentation(4)
    enable_treesitter_folding()

    require("config.keymaps").rust(event.buf)
  end,
})

-- ============================================================
-- Go
-- ============================================================

api.nvim_create_autocmd("FileType", {
  group = group,
  desc = "Configure Go buffers",
  pattern = "go",
  callback = function(event)
    set_indentation(4)

    require("config.keymaps").go(event.buf)
  end,
})

-- ============================================================
-- JavaScript and TypeScript
-- ============================================================

api.nvim_create_autocmd("FileType", {
  group = group,
  desc = "Configure JavaScript and TypeScript workflows",
  pattern = {
    "javascript",
    "javascriptreact",
    "typescript",
    "typescriptreact",
  },
  callback = function(event)
    require("config.keymaps").javascript(event.buf)
  end,
})
