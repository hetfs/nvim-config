
-- Stage 28: Ansible integration.
-- Run Ansible playbooks and roles directly from Neovim.
--
-- Plugin:
--   - nvim-ansible
--
-- Features:
--   - Detect Ansible playbooks and role files.
--   - Set ansible-doc as keywordprg when available.
--   - Navigate role files using gf.
--   - Execute playbooks and roles.
--
-- Keymaps:
--   - <leader>ta: Run Ansible playbook/role.
--     Available only in Ansible buffers.

vim.pack.add({
  {
    src = "https://github.com/mfussenegger/nvim-ansible",
    name = "nvim-ansible",
  },
})

-- ============================================================
-- Filetype-specific keymaps
-- ============================================================

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("AnsibleKeymaps", {
    clear = true,
  }),

  pattern = "yaml.ansible",

  callback = function(event)
    vim.keymap.set("n", "<leader>ta", function()
      require("ansible").run()
    end, {
      buffer = event.buf,
      desc = "Ansible: Run playbook/role",
      silent = true,
    })

    vim.keymap.set("v", "<leader>ta", function()
      require("ansible").run()
    end, {
      buffer = event.buf,
      desc = "Ansible: Run selected playbook/role",
      silent = true,
    })
  end,
})
