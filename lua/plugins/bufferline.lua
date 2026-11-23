-- Stage 25: Buffer navigation.
-- Display open buffers without requiring icon dependencies.

vim.pack.add({
  {
    src = "https://github.com/akinsho/bufferline.nvim",
    name = "bufferline.nvim",
  },
})

require("bufferline").setup({
  options = {
    mode = "buffers",
    style_preset = require("bufferline").style_preset.default,

    numbers = "ordinal",

    indicator = {
      style = "underline",
    },

    buffer_close_icon = "x",
    modified_icon = "*",
    close_icon = "x",
    left_trunc_marker = "<",
    right_trunc_marker = ">",

    max_name_length = 24,
    max_prefix_length = 15,
    tab_size = 18,

    show_buffer_icons = false,
    show_buffer_close_icons = false,
    show_close_icon = false,
    show_tab_indicators = true,

    separator_style = "thin",
    enforce_regular_tabs = false,
    always_show_bufferline = true,

    diagnostics = "nvim_lsp",
    diagnostics_update_in_insert = false,

    persist_buffer_sort = true,
    move_wraps_at_ends = false,

    sort_by = "insert_after_current",
  },
})
