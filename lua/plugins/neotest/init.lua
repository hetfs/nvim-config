-- Neotest
-- Native test orchestration and result presentation.

local M = {}

local function install()
  require("plugins.neotest.install").install()
end

local function configure()
  local neotest = require("neotest")

  neotest.setup({
    -- Adapter and project ownership.
    -- Adapters are registered by the project adapter registry.
    adapters = {},
    consumers = {},
    projects = {},

    -- Test discovery.
    discovery = {
      enabled = true,
      concurrent = 0,
    },

    -- Test execution.
    default_strategy = "integrated",

    running = {
      concurrent = true,
    },

    run = {
      enabled = true,
    },

    strategies = {
      integrated = {
        width = 120,
        height = 40,
      },
    },

    -- Automatic test dependency watching.
    -- Neotest's built-in language queries remain inherited.
    watch = {
      enabled = true,
    },

    -- Diagnostics.
    diagnostic = {
      enabled = true,
      severity = vim.diagnostic.severity.ERROR,
    },

    -- Test status presentation.
    status = {
      enabled = true,
      signs = true,
      virtual_text = false,
    },

    state = {
      enabled = true,
    },

    -- Test navigation.
    jump = {
      enabled = true,
    },

    -- Performance measurement.
    benchmark = {
      enabled = true,
    },

    -- Icons.
    icons = {
      child_indent = "│",
      child_prefix = "├",
      collapsed = "─",
      dir = "▸",
      expanded = "╮",
      failed = "✗",
      file = "▸",
      final_child_indent = " ",
      final_child_prefix = "╰",
      namespace = "▸",
      non_collapsible = "─",
      notify = "!",
      passed = "✓",
      running = "●",
      skipped = "○",
      test = "◆",
      unknown = "?",
      watching = "◉",

      running_animated = {
        "⠋",
        "⠙",
        "⠹",
        "⠸",
        "⠼",
        "⠴",
        "⠦",
        "⠧",
      },
    },

    -- Highlights.
    highlights = {
      adapter_name = "NeotestAdapterName",
      border = "NeotestBorder",
      dir = "NeotestDir",
      expand_marker = "NeotestExpandMarker",
      failed = "NeotestFailed",
      file = "NeotestFile",
      focused = "NeotestFocused",
      indent = "NeotestIndent",
      marked = "NeotestMarked",
      namespace = "NeotestNamespace",
      passed = "NeotestPassed",
      running = "NeotestRunning",
      select_win = "NeotestWinSelect",
      skipped = "NeotestSkipped",
      target = "NeotestTarget",
      test = "NeotestTest",
      unknown = "NeotestUnknown",
      watching = "NeotestWatching",
    },

    -- Individual test output.
    output = {
      enabled = true,
      open_on_run = false,
    },

    -- Dedicated output panel.
    output_panel = {
      enabled = true,
      open = "botright split | resize 15",
    },

    -- Test summary.
    summary = {
      enabled = true,
      animated = true,
      count = true,
      expand_errors = true,
      follow = true,
      open = "botright vsplit | vertical resize 50",

      mappings = {
        attach = "a",
        clear_marked = "M",
        clear_target = "T",
        debug = "d",
        debug_marked = "D",
        expand = { "<CR>", "<2-LeftMouse>" },
        expand_all = "e",
        help = "?",
        jumpto = "i",
        mark = "m",
        next_failed = "J",
        next_sibling = ">",
        output = "o",
        parent = "P",
        prev_failed = "K",
        prev_sibling = "<",
        run = "r",
        run_marked = "R",
        short = "O",
        stop = "u",
        target = "t",
        watch = "w",
      },
    },

    -- Quickfix integration.
    quickfix = {
      enabled = true,
      open = false,
    },

    -- Floating windows.
    floating = {
      border = "rounded",
      max_height = 0.6,
      max_width = 0.6,
      options = {},
    },

    -- Logging.
    log_level = vim.log.levels.WARN,
  })

  -- Register project-specific adapters after Neotest setup.
  require("plugins.neotest.adapters").setup_autocmds()
end

function M.setup()
  install()
  configure()
end

return M
