-- Native autocommands.

local group = vim.api.nvim_create_augroup("nvim_config", {
  clear = true,
})

-- Briefly highlight yanked text.
vim.api.nvim_create_autocmd("TextYankPost", {
  group = group,
  desc = "Highlight yanked text",
  callback = function()
    vim.hl.on_yank({
      timeout = 200,
    })
  end,
})

-- Restore the previous cursor position when reopening a file.
vim.api.nvim_create_autocmd("BufReadPost", {
  group = group,
  desc = "Restore cursor position",
  callback = function(event)
    local mark = vim.api.nvim_buf_get_mark(event.buf, '"')
    local line_count = vim.api.nvim_buf_line_count(event.buf)

    if mark[1] > 0 and mark[1] <= line_count then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- Keep splits balanced after a resize.
vim.api.nvim_create_autocmd("VimResized", {
  group = group,
  desc = "Rebalance windows after resize",
  callback = function()
    vim.cmd("wincmd =")
  end,
})
