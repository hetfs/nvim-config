-- Stage 12: Project root detection and navigation.
-- project.nvim manages project roots, working directories, and history.

vim.pack.add({
  {
    src = "https://github.com/DrKJeff16/project.nvim",
    name = "project.nvim",
  },
})

local project = require("project")

project.setup({
  -- Detect project roots automatically.
  manual_mode = false,

  -- Keep working-directory changes explicit.
  enable_autochdir = false,
  scope_chdir = "global",

  -- Detect roots using Git and supported marker files.
  use_git = true,

  -- Integrate with the existing LSP configuration.
  lsp = {
    enabled = true,
    use_pattern_matching = false,
    no_fallback = false,
  },

  -- Keep project.nvim picker integrations independent from
  -- Snacks Picker and fzf-lua.
})

-- Avoid the empty-history warning during shutdown.
-- project.nvim registers a VimLeavePre callback that writes history
-- even when there are no recent or current-session projects.
local project_history = require("project.util.history")

-- Replace project.nvim's unconditional shutdown callback with a
-- guarded callback that writes history only when projects exist.
for _, autocmd in
  ipairs(vim.api.nvim_get_autocmds({
    group = "project.nvim",
    event = "VimLeavePre",
  }))
do
  vim.api.nvim_del_autocmd(autocmd.id)
end

vim.api.nvim_create_autocmd("VimLeavePre", {
  group = vim.api.nvim_create_augroup("nvim_config_project_history", {
    clear = true,
  }),
  desc = "Persist project history when projects exist",
  callback = function()
    -- Avoid triggering an additional history write while checking.
    local projects = project_history.get_recent_projects(false, false, false)

    if #projects > 0 then
      project_history.write_history()
    end
  end,
})
