-- Stage 07: Snacks navigation.
-- Enable Picker, Explorer, and Dashboard.

vim.pack.add({
  {
    src = "https://github.com/folke/snacks.nvim",
    name = "snacks.nvim",
  },
})

-- Configure Snacks.
require("snacks").setup({
  -- ============================================================
  -- Picker
  -- ============================================================

  picker = {
    enabled = true,

    -- sources = {
    --   projects = {
    --     dev = {
    --       "D:\\workspace", -- Replace with your project parent directories.
    --     },
    --   },
    -- },
  },

  -- ============================================================
  -- Explorer
  -- ============================================================

  explorer = {
    enabled = true,
    replace_netrw = true,
  },

  -- ============================================================
  -- Dashboard
  -- ============================================================

  dashboard = {
    enabled = true,

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
          icon = " ",
          key = "c",
          desc = "Config",
          action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})",
        },
        {
          icon = " ",
          key = "s",
          desc = "Restore Session",
          action = [[:lua if type(MiniSessions) == "table" and type(MiniSessions.read) == "function" then MiniSessions.read() else vim.notify("Mini Sessions is not configured", vim.log.levels.WARN) end]],
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
    -- Dashboard item formatters
    -- ==========================================================

    formats = {
      icon = function(item)
        if item.file and (item.icon == "file" or item.icon == "directory") then
          return Snacks.dashboard.icon(item.file, item.icon)
        end

        return {
          item.icon,
          width = 2,
          hl = "icon",
        }
      end,

      footer = {
        "%s",
        align = "center",
      },

      header = {
        "%s",
        align = "center",
      },

      file = function(item, ctx)
        local fname = vim.fn.fnamemodify(item.file, ":~")
        local width = ctx.width

        if width and #fname > width then
          fname = vim.fn.pathshorten(fname)
        end

        if width and #fname > width then
          local dir = vim.fn.fnamemodify(fname, ":h")
          local file = vim.fn.fnamemodify(fname, ":t")
          local available = width - #dir - 2

          if available > 0 then
            file = file:sub(-available)
            fname = dir .. "/…" .. file
          else
            fname = file:sub(-width)
          end
        end

        local dir, file = fname:match("^(.*)/(.+)$")

        if dir then
          return {
            { dir .. "/", hl = "dir" },
            { file, hl = "file" },
          }
        end

        return {
          { fname, hl = "file" },
        }
      end,
    },

    -- ==========================================================
    -- Dashboard layout
    -- ==========================================================

    sections = {
      { section = "header" },
      { section = "keys", gap = 1, padding = 1 },
    },
  },
})

-- ============================================================
-- Platform compatibility
-- ============================================================

require("config.snacks").setup()

-- ============================================================
-- Snacks Picker workspace
-- ============================================================

vim.keymap.set("n", "<leader>fp", function()
  Snacks.picker.projects()
end, {
  desc = "Projects",
})

-- ============================================================
-- Snacks Navigation
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

vim.keymap.set("n", "<leader>fe", function()
  Snacks.explorer.open()
end, {
  desc = "Open file explorer",
})

