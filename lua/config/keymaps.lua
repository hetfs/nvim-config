-- Native Neovim keymaps.
-- Keep keymaps centralized and describe them for discoverability.
-- Enable deferred mappings only when their corresponding workflow is implemented.

local map = vim.keymap.set

-- ============================================================
-- Window Navigation and Resizing
-- ============================================================

map("n", "<C-h>", "<C-w><C-h>", { desc = "Focus left window" })
map("n", "<C-j>", "<C-w><C-j>", { desc = "Focus lower window" })
map("n", "<C-k>", "<C-w><C-k>", { desc = "Focus upper window" })
map("n", "<C-l>", "<C-w><C-l>", { desc = "Focus right window" })

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
-- Save
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
-- Buffer and Tab Navigation
-- ============================================================

-- Delete the current buffer without forcibly discarding changes.
map("n", "<S-q>", "<cmd>bdelete<CR>", {
  desc = "Close buffer",
})

map("n", "<leader>1", "1gt", { desc = "Go to tab 1" })
map("n", "<leader>2", "2gt", { desc = "Go to tab 2" })
map("n", "<leader>3", "3gt", { desc = "Go to tab 3" })
map("n", "<leader>4", "4gt", { desc = "Go to tab 4" })
map("n", "<leader>5", "5gt", { desc = "Go to tab 5" })

map("n", "<leader>t", "<cmd>tabnew<CR>", {
  desc = "New tab",
})
map("n", "<A-q>", "<cmd>tabclose<CR>", {
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

-- ===============================================
-- Native terminal workflow.
-- ===========================================================

map("t", "<Esc><Esc>", "<C-\\><C-n>", {
  desc = "Exit terminal mode",
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

-- Start a buffer-wide substitution using the previous search pattern.
-- Review the search and replacement before confirming the command.
map("n", "S", ":%s/<C-r>//g<Left><Left>", {
  desc = "Replace previous search in buffer",
})

-- ============================================================
-- Native Commenting
-- ============================================================

-- ============================================================
-- Deferred: Custom URL Mouse Handling
-- ============================================================

-- Enable when the URL-opening workflow has been implemented and tested.
-- This intentionally does not override Neovim's default mouse behavior yet.
--
-- local function url_in_line_at_col(line, col)
--   if not line or line == "" or not col or col < 1 then
--     return nil
--   end
--
--   local from = 1
--   while true do
--     local start_col, end_col = line:find("https?://%S+", from)
--     if not start_col then
--       return nil
--     end
--
--     if col >= start_col and col <= end_col then
--       local url = line:sub(start_col, end_col)
--       url = url:gsub("[%]%)%}%.,;:!?\"']+$", "")
--       return url ~= "" and url or nil
--     end
--
--     from = end_col + 1
--   end
-- end
--
-- map("n", "<LeftMouse>", function()
--   local mouse = vim.fn.getmousepos()
--
--   if mouse.winid and mouse.winid ~= 0
--     and mouse.line and mouse.line > 0
--     and mouse.column and mouse.column > 0
--   then
--     local ok_buf, bufnr = pcall(vim.api.nvim_win_get_buf, mouse.winid)
--     if ok_buf and bufnr then
--       local ok_line, lines = pcall(
--         vim.api.nvim_buf_get_lines,
--         bufnr,
--         mouse.line - 1,
--         mouse.line,
--         false
--       )
--
--       if ok_line then
--         local url = url_in_line_at_col(lines[1] or "", mouse.column)
--         if url then
--           vim.ui.open(url)
--           return
--         end
--       end
--     end
--   end
--
--   -- Preserve the default behavior for non-URL clicks.
--   vim.api.nvim_feedkeys(vim.keycode("<LeftMouse>"), "n", false)
-- end, {
--   desc = "Click URL to open in browser",
-- })

-- ============================================================
-- Deferred: Fenced Markdown Code-Block Extraction
-- ============================================================

-- Enable after the Treesitter stage provides and verifies the required
-- Markdown parser and grammar nodes.
--
-- map("n", "<leader>y", function()
--   local node = vim.treesitter.get_node()
--
--   while node and node:type() ~= "fenced_code_block" do
--     node = node:parent()
--   end
--
--   if not node then
--     vim.notify("Not inside a fenced code block", vim.log.levels.WARN)
--     return
--   end
--
--   for child in node:iter_children() do
--     if child:type() == "code_fence_content" then
--       local text = vim.treesitter.get_node_text(child, 0)
--       vim.fn.setreg("+", text)
--       vim.fn.setreg('"', text)
--       vim.notify("Code block copied to clipboard", vim.log.levels.INFO)
--       return
--     end
--   end
--
--   vim.notify("Code block is empty", vim.log.levels.WARN)
-- end, {
--   desc = "Yank fenced code block to clipboard",
-- })

-- ============================================================
-- Deferred: Diagnostics
-- ============================================================

-- Enable after the native diagnostics workflow is implemented and tested.
-- Note: setloclist populates the window's location list, not the
-- global quickfix list.
--
-- map("n", "<leader>q", vim.diagnostic.setloclist, {
--   desc = "Populate diagnostic location list",
-- })

-- ============================================================
-- Terminal
-- ============================================================

map("t", "<Esc><Esc>", "<C-\\><C-n>", {
  desc = "Exit terminal mode",
})

-- ============================================================
-- Deferred: Plugin Mappings
-- ============================================================

-- Alpha dashboard (requires the Alpha plugin and its configuration).
--
-- map("n", "<leader>a", "<cmd>Alpha<CR>", {
--   desc = "Open dashboard",
-- })

-- PasteImage (requires an approved image-pasting workflow).
--
-- map("n", "<leader>p", "<cmd>PasteImage<CR>", {
--   desc = "Paste image from clipboard",
-- })

-- Undotree (requires the Undotree plugin and its configuration).
--
-- map("n", "<F5>", "<cmd>UndotreeToggle<CR><cmd>UndotreeFocus<CR>", {
--   desc = "Toggle Undo tree",
-- })
