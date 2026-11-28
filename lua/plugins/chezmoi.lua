
-- Stage 30: Chezmoi dotfiles management.
-- Edit, browse, and apply chezmoi-managed configuration files.
--
-- Plugins:
--   - chezmoi.nvim
--   - plenary.nvim
--
-- Requirements:
--   - chezmoi CLI available in Neovim's PATH
--   - Snacks Picker
--
-- Features:
--   - Edit managed dotfiles.
--   - Browse managed files through Snacks Picker.
--   - Automatically watch files opened from the source directory.
--   - Apply watched changes when saved.
--   - Notify when files are opened or applied.
--   - Detect the source directory through `chezmoi source-path`.
--
-- Keymaps:
--   - <leader>sz: Browse chezmoi files.

-- ============================================================
-- Dependencies
-- ============================================================

vim.pack.add({
  {
    src = "https://github.com/nvim-lua/plenary.nvim",
    name = "plenary.nvim",
  },
  {
    src = "https://github.com/xvzc/chezmoi.nvim",
    name = "chezmoi.nvim",
  },
})

-- ============================================================
-- Configuration
-- ============================================================

require("chezmoi").setup({
  edit = {
    watch = false,
    force = false,

    ignore_patterns = {
      "run_onchange_.*",
      "run_once_.*",
      "%.chezmoiignore",
      "%.chezmoitemplate",
    },
  },

  events = {
    on_open = {
      notification = {
        enable = true,
        msg = "Opened a chezmoi-managed file",
        opts = {},
      },
    },

    on_watch = {
      notification = {
        enable = false,
        msg = "Watching chezmoi-managed file",
        opts = {},
      },
    },

    on_apply = {
      notification = {
        enable = true,
        msg = "Successfully applied chezmoi-managed file",
        opts = {},
      },
    },
  },
})

-- ============================================================
-- Resolve chezmoi source directory
-- ============================================================

local function get_source_dir()
  if vim.fn.executable("chezmoi") ~= 1 then
    vim.notify(
      "chezmoi CLI was not found in Neovim's PATH",
      vim.log.levels.WARN,
      { title = "Chezmoi" }
    )
    return nil
  end

  local output = vim.fn.systemlist({
    "chezmoi",
    "source-path",
  })

  if vim.v.shell_error ~= 0 or #output == 0 then
    vim.notify(
      "Failed to determine chezmoi source directory",
      vim.log.levels.WARN,
      { title = "Chezmoi" }
    )
    return nil
  end

  local source_dir = vim.trim(table.concat(output, "\n"))

  if source_dir == "" then
    vim.notify(
      "chezmoi returned an empty source directory",
      vim.log.levels.WARN,
      { title = "Chezmoi" }
    )
    return nil
  end

  return vim.fs.normalize(source_dir)
end

local source_dir = get_source_dir()

-- ============================================================
-- Automatically watch files in the chezmoi source directory
-- ============================================================

if source_dir then
  local group = vim.api.nvim_create_augroup("ChezmoiAutoWatch", {
    clear = true,
  })

  vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
    group = group,

    callback = function(event)
      local bufnr = event.buf
      local filepath = vim.api.nvim_buf_get_name(bufnr)

      if filepath == "" then
        return
      end

      -- vim.fs.relpath returns nil when the file is outside
      -- the chezmoi source directory.
      local relative_path = vim.fs.relpath(source_dir, filepath)

      if not relative_path or relative_path == "." then
        return
      end

      vim.schedule(function()
        if not vim.api.nvim_buf_is_valid(bufnr) then
          return
        end

        require("chezmoi.commands.__edit").watch(bufnr)
      end)
    end,
  })
end

-- ============================================================
-- Keymaps
-- ============================================================

vim.keymap.set("n", "<leader>sz", function()
  require("chezmoi.pick").snacks()
end, {
  desc = "Browse chezmoi files",
})
