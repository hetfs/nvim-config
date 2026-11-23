-- Stage 18: Yank history.
-- Preserve native registers and the centralized keymap architecture.

vim.pack.add({
  {
    src = "https://github.com/gbprod/yanky.nvim",
    name = "yanky.nvim",
  },
})

require("yanky").setup({
  ring = {
    history_length = 100,
    storage = "shada",

    -- Let Neovim manage numbered delete registers.
    sync_with_numbered_registers = false,

    -- Never record black-hole register operations.
    ignore_registers = { "_" },

    -- Keep actual yanks, but exclude deletes and changes.
    filter = function(_, context)
      if context.source ~= "yank" then
        return true
      end

      return context.event ~= nil and context.event.operator == "y"
    end,
  },

  -- External clipboard copies are not imported into yank history.
  -- Neovim's unnamedplus clipboard option remains unchanged.
  system_clipboard = {
    sync_with_ring = false,
  },

  highlight = {
    on_put = true,
    on_yank = true,
    timer = 500,
  },

  preserve_cursor_position = {
    enabled = true,
  },
})
