-- Stage 12: Session management.
-- Reuse the shared mini.nvim installation.
--
-- Global sessions:
--   Stored under Neovim's data directory.
--
-- Project sessions:
--   Stored as Session.vim in the project root.
--
-- Commands:
--   :SessionSave       Save the current project session.
--   :SessionSave name  Save a named global session.
--   :SessionLoad       Select and load a session.
--   :SessionDelete     Select and delete a session.
--   :SessionRestart    Restart Neovim preserving the session.

local sessions = require("mini.sessions")

sessions.setup({
  -- Restore sessions only when explicitly requested.
  autoread = false,

  -- Automatically save an active session before exiting.
  autowrite = true,

  -- Use mini.sessions' default global session directory.
  -- Usually: stdpath('data')/session

  -- Project-local session filename.
  file = "Session.vim",

  -- Avoid overwriting existing sessions by default.
  force = {
    read = false,
    write = false,
    delete = false,
  },

  -- Report session operations.
  verbose = {
    read = true,
    write = true,
    delete = true,
  },
})

-- Save the current project session.
vim.api.nvim_create_user_command("SessionSave", function(opts)
  local name = opts.args

  if name == "" then
    name = sessions.config.file
  end

  sessions.write(name)
end, {
  nargs = "?",
  desc = "Save a project or named global session",
})

-- Select and load an existing session.
vim.api.nvim_create_user_command("SessionLoad", function()
  sessions.select("read")
end, {
  desc = "Select and load a session",
})

-- Select and delete an existing session.
vim.api.nvim_create_user_command("SessionDelete", function()
  sessions.select("delete")
end, {
  desc = "Select and delete a session",
})

-- Restart Neovim while preserving the current session.
vim.api.nvim_create_user_command("SessionRestart", function()
  sessions.restart()
end, {
  desc = "Restart Neovim preserving the session",
})

-- Session keymaps.
vim.keymap.set("n", "<leader>ss", "<cmd>SessionSave<cr>", {
  desc = "Save project session",
})

vim.keymap.set("n", "<leader>sS", function()
  vim.ui.input({
    prompt = "Global session name: ",
  }, function(name)
    if name and name ~= "" then
      sessions.write(name)
    end
  end)
end, {
  desc = "Save named global session",
})

vim.keymap.set("n", "<leader>sl", "<cmd>SessionLoad<cr>", {
  desc = "Load session",
})

vim.keymap.set("n", "<leader>sd", "<cmd>SessionDelete<cr>", {
  desc = "Delete session",
})

vim.keymap.set("n", "<leader>sr", "<cmd>SessionRestart<cr>", {
  desc = "Restart with session",
})

