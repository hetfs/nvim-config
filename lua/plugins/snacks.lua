-- Stage 07: Snacks navigation.
-- Enable Picker, Explorer, and Dashboard.
--
-- Dependencies:
--   - mini.sessions: session management
--   - project.nvim: project root detection and history
--   - fd: fast file discovery
--   - ripgrep: content searching
--   - Nerd Font: dashboard and picker icons (optional)
--
-- Compatibility:
--   - Uses vim.pack, not lazy.nvim.
--   - Does not use the Lazy.nvim-dependent dashboard startup section.
--   - Restores sessions directly through MiniSessions.

vim.pack.add({
  {
    src = "https://github.com/folke/snacks.nvim",
    name = "snacks.nvim",
  },
})

local snacks = require("snacks")

-- ============================================================
-- Session integration
-- ============================================================

local function restore_session()
  local sessions = rawget(_G, "MiniSessions")

  if type(sessions) ~= "table" or type(sessions.select) ~= "function" then
    vim.notify(
      "mini.sessions is not configured or loaded",
      vim.log.levels.WARN,
      { title = "Snacks Dashboard" }
    )
    return
  end

  local ok, err = pcall(sessions.select, "read")

  if not ok then
    vim.notify(
      "Unable to open the session selector:\n" .. tostring(err),
      vim.log.levels.ERROR,
      { title = "Snacks Dashboard" }
    )
  end
end

-- ============================================================
-- Snacks configuration
-- ============================================================

snacks.setup({
  -- ==========================================================
  -- Picker
  -- ==========================================================

  picker = {
    enabled = true,

    prompt = " ",

    layout = {
      preset = "default",
    },

    -- Optional project parent directories.
    --
    -- Configure these if you want Snacks to discover projects
    -- outside the Git roots of your recent files.
    --
    -- sources = {
    --   projects = {
    --     dev = {
    --       "D:/workspace",
    --       "D:/projects",
    --     },
    --     recent = true,
    --   },
    -- },
  },

  -- ==========================================================
  -- Explorer
  -- ==========================================================

  explorer = {
    enabled = true,

    -- Replace Neovim's built-in netrw directory browser.
    replace_netrw = true,

    -- Move deleted files to the system trash.
    trash = true,
  },

  -- ==========================================================
  -- Dashboard
  -- ==========================================================

  dashboard = {
    enabled = true,

    -- Dashboard shortcuts.
    preset = {
      keys = {
        {
          icon = " ",
          key = "f",
          desc = "Find File",
          action = ":lua Snacks.dashboard.pick('files')",
        },

        {
          icon = " ",
          key = "n",
          desc = "New File",
          action = ":ene | startinsert",
        },

        {
          icon = " ",
          key = "g",
          desc = "Find Text",
          action = ":lua Snacks.dashboard.pick('live_grep')",
        },

        {
          icon = " ",
          key = "r",
          desc = "Recent Files",
          action = ":lua Snacks.dashboard.pick('oldfiles')",
        },

        {
          icon = " ",
          key = "p",
          desc = "Projects",
          action = ":lua Snacks.picker.projects()",
        },

        {
          icon = " ",
          key = "c",
          desc = "Config",
          action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})",
        },

        {
          icon = " ",
          key = "s",
          desc = "Restore Session",
          action = restore_session,
        },

        {
          icon = " ",
          key = "q",
          desc = "Quit",
          action = ":qa",
        },
      },

      -- HETFS ASCII banner.
      -- https://github.com/hetfs
      header = [[
██╗  ██╗ ███████╗ ████████╗ ███████╗ ███████╗
██║  ██║ ██╔════╝ ╚══██╔══╝ ██╔════╝ ██╔════╝
███████║ █████╗      ██║    █████╗   ███████╗
██╔══██║ ██╔══╝      ██║    ██╔══╝   ╚════██║
██║  ██║ ███████╗    ██║    ██║      ███████║
╚═╝  ╚═╝ ╚══════╝    ╚═╝    ╚═╝      ╚══════╝

       [ HEALTH  /  EDUCATION  /  TECHNOLOGY ]

           [ FARMING  /  STARTUPS ]

         > CODE FOR A BRIGHTER FUTURE_
]],
    },

    -- ==========================================================
    -- Dashboard formatting
    -- ==========================================================

    formats = {
      file = function(item, ctx)
        if not item.file then
          return {}
        end

        local filename = vim.fn.fnamemodify(item.file, ":~")
        local width = ctx.width

        if width and vim.fn.strdisplaywidth(filename) > width then
          filename = vim.fn.pathshorten(filename)
        end

        if width and vim.fn.strdisplaywidth(filename) > width then
          local directory = vim.fn.fnamemodify(filename, ":h")
          local basename = vim.fn.fnamemodify(filename, ":t")

          local available = width - vim.fn.strdisplaywidth(directory) - 2

          if available > 0 then
            basename = vim.fn.strcharpart(
              basename,
              math.max(0, vim.fn.strchars(basename) - available)
            )

            filename = directory .. "/…" .. basename
          else
            filename = vim.fn.strcharpart(
              filename,
              math.max(0, vim.fn.strchars(filename) - width)
            )
          end
        end

        local directory, basename = filename:match("^(.*)/(.+)$")

        if directory then
          return {
            { directory .. "/", hl = "dir" },
            { basename, hl = "file" },
          }
        end

        return {
          { filename, hl = "file" },
        }
      end,
    },

    -- ==========================================================
    -- Dashboard layout
    -- ==========================================================

    -- Explicitly define the sections.
    -- Do not add { section = "startup" } here:
    -- that section calls require("lazy.stats").
    sections = {
      {
        section = "header",
      },

      {
        section = "keys",
        gap = 1,
        padding = 1,
      },

      {
        section = "recent_files",
        title = "Recent Files",
        icon = " ",
        limit = 5,
        indent = 2,
        padding = 1,
      },

      {
        section = "projects",
        title = "Recent Projects",
        icon = " ",
        limit = 5,
        indent = 2,
        padding = 1,
      },
    },
  },
})

-- ============================================================
-- Platform compatibility
-- ============================================================

require("config.snacks").setup()

-- ============================================================
-- Snacks Picker
-- ============================================================

vim.keymap.set("n", "<leader>ff", function()
  Snacks.picker.files()
end, {
  desc = "Find files",
})

vim.keymap.set("n", "<leader>fg", function()
  Snacks.picker.grep()
end, {
  desc = "Search file contents",
})

vim.keymap.set("n", "<leader>fb", function()
  Snacks.picker.buffers()
end, {
  desc = "Find buffers",
})

vim.keymap.set("n", "<leader>fr", function()
  Snacks.picker.oldfiles()
end, {
  desc = "Recent files",
})

vim.keymap.set("n", "<leader>fp", function()
  Snacks.picker.projects()
end, {
  desc = "Find projects",
})

vim.keymap.set("n", "<leader>fc", function()
  Snacks.picker.files({
    cwd = vim.fn.stdpath("config"),
  })
end, {
  desc = "Find Neovim config files",
})

-- ============================================================
-- Snacks Explorer
-- ============================================================

vim.keymap.set("n", "<leader>fe", function()
  Snacks.explorer.open()
end, {
  desc = "Open file explorer",
})

vim.keymap.set("n", "<leader>fE", function()
  Snacks.explorer.reveal()
end, {
  desc = "Reveal current file",
})

-- ============================================================
-- Snacks Dashboard
-- ============================================================

vim.keymap.set("n", "<leader>fd", function()
  Snacks.dashboard()
end, {
  desc = "Open dashboard",
})

-- ============================================================
-- Session management
-- ============================================================

vim.keymap.set("n", "<leader>fs", restore_session, {
  desc = "Restore session",
})

