-- Stage 12: Session management.
-- Reuse the shared mini.nvim installation.

require("mini.sessions").setup({
  -- Restore sessions only when explicitly requested.
  autoread = false,

  -- Do not write sessions automatically on exit.
  autowrite = false,

  -- Store named global sessions under Neovim's data directory.
  -- The module uses its default session directory when omitted.

  -- Store project-local sessions as Session.vim in the current directory.
  file = "Session.vim",

  -- Do not overwrite an existing session when saving.
  force = {
    read = false,
    write = false,
    delete = false,
  },

  -- Keep session actions explicit and predictable.
  verbose = {
    read = true,
    write = true,
    delete = true,
  },
})
