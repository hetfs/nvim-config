
-- Stage: Better Escape.
-- Enable the jk escape sequence only in explicitly selected filetypes.
--
-- Add filetypes to `enabled_filetypes` to opt in.
-- In all other filetypes, `jk` is inserted normally.

vim.pack.add({
  {
    src = "https://github.com/max397574/better-escape.nvim",
    name = "better-escape.nvim",
  },
})

local enabled_filetypes = {
  -- Opt in by uncommenting or adding filetypes:
  lua = true,
  python = true,
  rust = true,
  -- go = true,
  -- javascript = true,
  -- typescript = true,
  -- markdown = true,
}

local group = vim.api.nvim_create_augroup("BetterEscapeFiletypes", {
  clear = true,
})

-- Track whether the current buffer's filetype has opted in.
local function set_buffer_state(buf)
  local filetype = vim.bo[buf].filetype

  vim.b[buf].better_escape_enabled =
    enabled_filetypes[filetype] == true
end

vim.api.nvim_create_autocmd("FileType", {
  group = group,
  callback = function(event)
    set_buffer_state(event.buf)
  end,
})

-- Handle buffers whose filetype was already detected.
for _, buf in ipairs(vim.api.nvim_list_bufs()) do
  if vim.api.nvim_buf_is_loaded(buf) then
    set_buffer_state(buf)
  end
end

require("better_escape").setup({
  timeout = vim.o.timeoutlen,
  default_mappings = false,

  mappings = {
    i = {
      j = {
        k = function()
          if vim.b.better_escape_enabled then
            return "<Esc>"
          end

          -- Preserve literal "jk" in non-opted-in buffers.
          return "jk"
        end,
      },
    },
  },
})

