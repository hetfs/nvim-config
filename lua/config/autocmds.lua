 -- Native autocommands.

local group = vim.api.nvim_create_augroup("nvim_config", {
  clear = true,
})

-- ============================================================
-- Yank Highlighting
-- ============================================================

vim.api.nvim_create_autocmd("TextYankPost", {
  group = group,
  desc = "Highlight yanked text",
  callback = function()
    vim.hl.on_yank({
      timeout = 200,
    })
  end,
})

-- ============================================================
-- External File Changes
-- ============================================================

vim.api.nvim_create_autocmd({
  "FocusGained",
  "TermClose",
  "TermLeave",
}, {
  group = group,
  desc = "Reload files changed outside Neovim",
  callback = function()
    vim.cmd("checktime")
  end,
})

-- ============================================================
-- Cursor Position Restoration
-- ============================================================

vim.api.nvim_create_autocmd("BufReadPost", {
  group = group,
  desc = "Restore previous cursor position",
  callback = function(event)
    -- Ignore special buffers.
    if vim.bo[event.buf].buftype ~= "" then
      return
    end

    local win = vim.api.nvim_get_current_win()

    -- Ensure the current window displays the event buffer.
    if vim.api.nvim_win_get_buf(win) ~= event.buf then
      return
    end

    local mark = vim.api.nvim_buf_get_mark(event.buf, '"')
    local line_count = vim.api.nvim_buf_line_count(event.buf)

    if mark[1] > 0 and mark[1] <= line_count then
      pcall(vim.api.nvim_win_set_cursor, win, mark)
    end
  end,
})

-- ============================================================
-- Window Management
-- ============================================================

vim.api.nvim_create_autocmd("VimResized", {
  group = group,
  desc = "Rebalance windows after resize",
  callback = function()
    vim.cmd("tabdo wincmd =")
  end,
})

-- ============================================================
-- Help and Utility Windows
-- ============================================================

vim.api.nvim_create_autocmd("FileType", {
  group = group,
  desc = "Close help-like windows with q",
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
      desc = "Close window",
    })
  end,
})

-- ============================================================
-- Writing and Prose
-- ============================================================

vim.api.nvim_create_autocmd("FileType", {
  group = group,
  desc = "Wrap and spellcheck prose",
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
-- File Saving
-- ============================================================

vim.api.nvim_create_autocmd("BufWritePre", {
  group = group,
  desc = "Create missing parent directories before saving",
  callback = function(event)
    -- Ignore URI-based buffers.
    if event.match:match("^%a[%w+.-]*://") then
      return
    end

    local dir = vim.fn.fnamemodify(event.file, ":p:h")

    if vim.fn.isdirectory(dir) == 1 then
      return
    end

    local result = vim.fn.mkdir(dir, "p")

    if result == 0 and vim.fn.isdirectory(dir) == 0 then
      error("Failed to create parent directory: " .. dir)
    end
  end,
})