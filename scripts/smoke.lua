-- Usage:
--   stylua --check .
--   nvim --headless -u NONE -l scripts/check-syntax.lua
--   nvim --headless -u init.lua -c "luafile scripts/smoke.lua"
--   git diff --check

local function check(condition, message)
  if not condition then
    error("FAIL nvim-config: " .. message, 2)
  end
end

local function check_equal(actual, expected, message)
  check(vim.deep_equal(actual, expected), string.format("%s (expected %s, got %s)", message, vim.inspect(expected), vim.inspect(actual)))
end

local function check_mapping(mode, lhs, description, context)
  local mapping = vim.fn.maparg(lhs, mode, false, true)
  local exists = type(mapping) == "table" and next(mapping) ~= nil

  check(exists, context .. " mapping exists: " .. mode .. " " .. lhs)

  if exists and description then
    check_equal(mapping.desc, description, context .. " mapping description: " .. lhs)
  end

  return mapping
end

local function check_module_failure_contract(root)
  check(type(vim.system) == "function", "vim.system() is required for the subprocess failure test")

  local init_path = root .. "/init.lua"

  -- Inject an intentional failure in config.options.
  local preload_options = [[lua package.preload["config.options"] = function() error("STAGE04_INTENTIONAL_MODULE_FAILURE") end]]

  -- This marker must never appear because options fails first.
  local preload_keymaps = [[lua package.preload["config.keymaps"] = function() print("STAGE04_UNEXPECTED_KEYMAPS_LOADED"); return true end]]

  local result = vim
    .system({
      vim.v.progpath,
      "--headless",
      "-i",
      "NONE",
      "-u",
      "NONE",
      "--cmd",
      preload_options,
      "--cmd",
      preload_keymaps,
      "-c",
      "luafile " .. vim.fn.fnameescape(init_path),
      "-c",
      "qa!",
    }, {
      text = true,
    })
    :wait(5000)

  check(type(result) == "table", "failure-test subprocess returned a result")

  local output = (result.stdout or "") .. "\n" .. (result.stderr or "")

  check(result.code ~= 124, "failure-test subprocess timed out\n" .. output)

  check(
    output:find("STAGE04_INTENTIONAL_MODULE_FAILURE", 1, true) ~= nil,
    table.concat({
      "required-module error is visible in subprocess output",
      "Subprocess exit code: " .. tostring(result.code),
      "Subprocess signal: " .. tostring(result.signal),
      "Subprocess stdout:",
      tostring(result.stdout),
      "Subprocess stderr:",
      tostring(result.stderr),
    }, "\n")
  )

  check(output:find("STAGE04_UNEXPECTED_KEYMAPS_LOADED", 1, true) == nil, "keymaps module does not load after options module fails\n" .. output)

  print("PASS module failure contract")
end

local function check_native_grep()
  check(vim.fn.executable("rg") == 1, "ripgrep (rg) must be available for the native grep workflow")

  -- Exercise Neovim's native grep integration and quickfix population.
  vim.cmd("silent grep! Stage scripts/smoke.lua")

  local quickfix = vim.fn.getqflist()

  check(#quickfix > 0, "native grep populates the quickfix list")

  for _, item in ipairs(quickfix) do
    check(item.valid == 1, "native grep produces valid quickfix entries")
    check(item.lnum > 0, "quickfix result contains a valid line number")
    check(item.col > 0, "quickfix result contains a valid column")
    check(item.text ~= "", "quickfix result contains matching text")
  end

  print("PASS native grep and quickfix")
end

-- Stage 04: Verify native gcc/gc commenting behavior.
local function check_native_commenting()
  local original_buf = vim.api.nvim_get_current_buf()
  local buf = vim.api.nvim_create_buf(false, true)

  check(buf ~= 0, "create scratch buffer for native commenting")

  vim.api.nvim_set_current_buf(buf)
  vim.bo[buf].filetype = "lua"
  vim.bo[buf].commentstring = "-- %s"

  local original_lines = {
    "local alpha = 1",
    "local beta = 2",
    "local gamma = 3",
  }

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, original_lines)

  -- Toggle the current line into a comment.
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  vim.cmd("normal gcc")

  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

  check_equal(lines[1], "-- local alpha = 1", "gcc comments the current line")

  -- Toggle the current line back into code.
  vim.cmd("normal gcc")

  lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

  check_equal(lines[1], "local alpha = 1", "gcc uncomments the current line")

  -- Toggle three lines into comments.
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  vim.cmd("normal 3gcc")

  lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

  for index, line in ipairs(original_lines) do
    check_equal(lines[index], "-- " .. line, "3gcc comments line " .. index)
  end

  -- Toggle the three lines back into code.
  vim.cmd("normal 3gcc")

  lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

  for index, line in ipairs(original_lines) do
    check_equal(lines[index], line, "3gcc uncomments line " .. index)
  end

  vim.api.nvim_set_current_buf(original_buf)
  vim.api.nvim_buf_delete(buf, { force = true })

  print("PASS native commenting")
end

local function check_stage06_plugins()
  local mini_icons = package.loaded["mini.icons"]

  check(type(mini_icons) == "table" and type(mini_icons.get) == "function", "mini.icons loaded and exposes its get() API")

  local which_key = package.loaded["which-key"]

  check(type(which_key) == "table" and type(which_key.show) == "function", "which-key.nvim loaded and exposes its show() API")

  print("PASS Stage 06 plugin loading")
end

local function check_stage07_snacks()
  local snacks = package.loaded["snacks"]

  check(type(snacks) == "table", "Snacks module was loaded")

  if type(snacks) ~= "table" then
    return
  end

  check(type(snacks.picker) == "table", "Snacks Picker API is available")

  if type(snacks.picker) == "table" then
    check(type(snacks.picker.files) == "function", "Snacks file picker is available")
    check(type(snacks.picker.grep) == "function", "Snacks grep picker is available")
    check(type(snacks.picker.buffers) == "function", "Snacks buffer picker is available")
  end

  check(type(snacks.explorer) == "table", "Snacks Explorer API is available")

  if type(snacks.explorer) == "table" then
    check(type(snacks.explorer.open) == "function", "Snacks Explorer open API is available")
  end

  local mappings = {
    { lhs = "<leader>ff", desc = "Find files" },
    { lhs = "<leader>fg", desc = "Search file contents" },
    { lhs = "<leader>fb", desc = "Find buffers" },
    { lhs = "<leader>fe", desc = "Open file explorer" },
  }

  for _, expected in ipairs(mappings) do
    check_mapping("n", expected.lhs, expected.desc, "Snacks")
  end

  print("PASS Stage 07 Snacks navigation registration")
end

local function check_stage07_fzf_lua()
  local fzf_lua = package.loaded["fzf-lua"]

  check(type(fzf_lua) == "table", "fzf-lua module was loaded")

  if type(fzf_lua) ~= "table" then
    return
  end

  check(type(fzf_lua.files) == "function", "fzf-lua file picker is available")
  check(type(fzf_lua.live_grep) == "function", "fzf-lua live grep picker is available")
  check(type(fzf_lua.buffers) == "function", "fzf-lua buffer picker is available")
  check(type(fzf_lua.resume) == "function", "fzf-lua resume API is available")

  local mappings = {
    { lhs = "<leader>pf", desc = "Fzf: Find files" },
    { lhs = "<leader>pg", desc = "Fzf: Search file contents" },
    { lhs = "<leader>pb", desc = "Fzf: Find buffers" },
    { lhs = "<leader>pr", desc = "Fzf: Resume picker" },
  }

  for _, expected in ipairs(mappings) do
    check_mapping("n", expected.lhs, expected.desc, "fzf-lua")
  end

  print("PASS Stage 07 fzf-lua navigation registration")
end

local function check_stage07_flash()
  local flash = package.loaded["flash"]

  check(type(flash) == "table", "flash.nvim module was loaded")

  if type(flash) ~= "table" then
    return
  end

  check(type(flash.jump) == "function", "Flash jump API is available")
  check(type(flash.treesitter) == "function", "Flash Treesitter API is available")
  check(type(flash.remote) == "function", "Flash remote API is available")
  check(type(flash.treesitter_search) == "function", "Flash Treesitter search API is available")
  check(type(flash.toggle) == "function", "Flash toggle API is available")

  local mappings = {
    { mode = "n", lhs = "s", desc = "Flash: Jump" },
    { mode = "n", lhs = "gs", desc = "Flash: Treesitter jump" },
    { mode = "o", lhs = "r", desc = "Flash: Remote operation" },
    { mode = "x", lhs = "R", desc = "Flash: Treesitter search" },
    { mode = "c", lhs = "<C-s>", desc = "Flash: Toggle search labels" },
  }

  for _, expected in ipairs(mappings) do
    check_mapping(expected.mode, expected.lhs, expected.desc, "Flash")
  end

  print("PASS Stage 07 flash.nvim registration")
end

local function check_stage07_mini_ai()
  local mini_ai = package.loaded["mini.ai"]

  check(type(mini_ai) == "table", "mini.ai module was loaded")

  if type(mini_ai) ~= "table" then
    return
  end

  check(type(mini_ai.setup) == "function", "mini.ai setup API is available")
  check(type(mini_ai.find_textobject) == "function", "mini.ai textobject API is available")
  check(type(_G.MiniAi) == "table", "mini.ai global module is available")

  print("PASS Stage 07 mini.ai loading")
end

local function check_stage07_mini_surround()
  local mini_surround = package.loaded["mini.surround"]

  check(type(mini_surround) == "table", "mini.surround module was loaded")

  if type(mini_surround) ~= "table" then
    return
  end

  check(type(mini_surround.setup) == "function", "mini.surround setup API is available")
  check(type(_G.MiniSurround) == "table", "mini.surround global module is available")

  check_mapping("n", "sa", nil, "mini.surround")
  check_mapping("n", "sd", nil, "mini.surround")
  check_mapping("n", "sr", nil, "mini.surround")

  print("PASS Stage 07 mini.surround registration")
end

local function check_stage07_mini_move()
  local mini_move = package.loaded["mini.move"]

  check(type(mini_move) == "table", "mini.move module was loaded")

  if type(mini_move) ~= "table" then
    return
  end

  check(type(mini_move.setup) == "function", "mini.move setup API is available")
  check(type(_G.MiniMove) == "table", "mini.move global module is available")

  for _, lhs in ipairs({ "<M-h>", "<M-j>", "<M-k>", "<M-l>" }) do
    check_mapping("n", lhs, nil, "mini.move Normal")
    check_mapping("x", lhs, nil, "mini.move Visual")
  end

  print("PASS Stage 07 mini.move registration")
end

local function check_stage07_dial()
  local dial = package.loaded["dial.map"]

  check(type(dial) == "table", "dial.nvim mapping module was loaded")

  if type(dial) ~= "table" then
    return
  end

  check(type(dial.inc_normal) == "function", "Dial normal increment API is available")
  check(type(dial.dec_normal) == "function", "Dial normal decrement API is available")
  check(type(dial.inc_visual) == "function", "Dial visual increment API is available")
  check(type(dial.dec_visual) == "function", "Dial visual decrement API is available")

  local mappings = {
    { mode = "n", lhs = "<C-a>", desc = "Dial: Increment" },
    { mode = "n", lhs = "<C-x>", desc = "Dial: Decrement" },
    { mode = "x", lhs = "<C-a>", desc = "Dial: Increment selection" },
    { mode = "x", lhs = "<C-x>", desc = "Dial: Decrement selection" },
  }

  for _, expected in ipairs(mappings) do
    check_mapping(expected.mode, expected.lhs, expected.desc, "Dial")
  end

  print("PASS Stage 07 dial.nvim registration")
end

local function check_stage07_plugins()
  check_stage07_snacks()
  check_stage07_fzf_lua()
  check_stage07_flash()
  check_stage07_mini_ai()
  check_stage07_mini_surround()
  check_stage07_mini_move()
  check_stage07_dial()

  print("PASS Stage 07 plugin registration")
end

local function check_stage11_formatting()
  local conform = require("conform")
  local formatting = require("config.format")
  local language_config = require("config.languages")

  check(type(formatting.setup) == "function", "Formatting setup function is available")
  check(type(formatting.format) == "function", "Manual formatting function is available")
  check(type(formatting.resolve) == "function", "Formatter resolver is available")
  check(type(conform.setup) == "function", "Conform setup API is available")
  check(type(conform.format) == "function", "Conform format API is available")
  check(type(conform.list_formatters_to_run) == "function", "Conform formatter discovery API is available")

  -- Verify that language-pack formatter metadata is available.
  local defaults = require("langs").collect("formatters")

  check(type(defaults) == "table", "Language-pack formatter metadata is available")
  check(type(defaults.lua) == "table", "Lua formatter defaults are available")
  check(vim.tbl_contains(defaults.lua, "stylua"), "StyLua is the Lua default formatter")

  -- Verify preference ordering, deduplication, and Conform metadata.
  local resolved = formatting.resolve({
    lua = { "stylua", "fallback" },
    typescript = { "prettier", "biome" },
  }, {
    preferred = {
      lua = { "fallback", "fallback", "stylua" },
      typescript = { "biome" },
    },
    stop_after_first = {
      typescript = true,
    },
    formatters_only = {},
  })

  check_equal(resolved.lua, { "fallback", "stylua" }, "Formatter preferences precede defaults and duplicate names are removed")

  check_equal(resolved.typescript, { "biome", "prettier", stop_after_first = true }, "stop_after_first is preserved in the resolved Conform configuration")

  -- Verify that formatters_only excludes language-pack defaults.
  local restricted = formatting.resolve({
    lua = { "stylua", "fallback" },
  }, {
    preferred = {
      lua = { "custom" },
    },
    stop_after_first = {},
    formatters_only = {
      lua = true,
    },
  })

  check_equal(restricted.lua, { "custom" }, "formatters_only restricts the filetype to preferred formatters")

  -- Verify that formatters_only rejects an empty preferred list.
  local ok, err = pcall(function()
    formatting.resolve({ lua = { "stylua" } }, {
      preferred = {},
      stop_after_first = {},
      formatters_only = { lua = true },
    })
  end)

  check(not ok, "formatters_only rejects an empty preferred formatter list")
  check(tostring(err):find("formatters_only.lua", 1, true) ~= nil, "Invalid formatters_only configuration reports the filetype")

  -- Capture setup configuration without changing the live Conform setup.
  -- All monkey patches and package.loaded changes are restored even on error.
  local original_conform_setup = conform.setup
  local original_create_user_command = vim.api.nvim_create_user_command
  local original_language_config = package.loaded["config.languages"]

  local captured_config
  local captured_command

  local function capture_setup_config(config)
    captured_config = config
  end

  local function capture_user_command(name, callback, opts)
    captured_command = {
      name = name,
      callback = callback,
      opts = opts,
    }
  end

  local function run_setup_with_language_config(config)
    captured_config = nil
    captured_command = nil

    local setup_ok, setup_err = xpcall(function()
      package.loaded["config.languages"] = config
      conform.setup = capture_setup_config
      vim.api.nvim_create_user_command = capture_user_command

      formatting.setup()
    end, debug.traceback)

    -- Restore shared state regardless of the setup result.
    conform.setup = original_conform_setup
    vim.api.nvim_create_user_command = original_create_user_command
    package.loaded["config.languages"] = original_language_config

    if not setup_ok then
      error(setup_err, 0)
    end

    return captured_config, captured_command
  end

  -- The normal configuration must leave format-on-save disabled.
  local default_config, default_command = run_setup_with_language_config(language_config)

  check(type(default_config) == "table", "Formatting setup produces a Conform configuration")
  check(default_config.format_on_save == nil, "Format-on-save is disabled in the default configuration")
  check_equal(default_config.default_format_opts, { lsp_format = "never" }, "LSP formatting fallback is disabled")
  check(type(default_config.formatters_by_ft) == "table", "Conform receives resolved formatters_by_ft")
  check(default_command ~= nil, "Formatting setup registers the :Format command")
  check_equal(default_command.name, "Format", "Formatting setup registers the expected command name")
  check(type(default_command.callback) == "function", ":Format is registered with a callback")
  check_equal(default_command.opts, { desc = "Format current buffer" }, ":Format receives the expected description")

  -- Explicit opt-in should enable format-on-save with a safe LSP policy.
  local enabled_language_config = vim.deepcopy(language_config)
  enabled_language_config.format_on_save = {
    enabled = true,
    timeout_ms = 750,
  }

  local enabled_config = run_setup_with_language_config(enabled_language_config)

  check_equal(enabled_config.format_on_save, {
    timeout_ms = 750,
    lsp_format = "never",
  }, "Format-on-save opt-in uses the configured timeout and disables LSP fallback")

  -- Verify the real command is registered after normal startup.
  -- Do not depend on nvim_get_commands().desc: command metadata may expose
  -- the description differently across Neovim versions.
  local command_info = vim.api.nvim_get_commands({})["Format"]

  check(command_info ~= nil, ":Format exists after normal configuration loading")

  -- Confirm the formatting callback requests asynchronous Conform formatting
  -- and explicitly disables LSP formatting. No external formatter is run.
  local original_list_formatters = conform.list_formatters_to_run
  local original_format = conform.format
  local original_notify = vim.notify

  local test_bufnr = vim.api.nvim_get_current_buf()
  local original_buf_option = vim.bo[test_bufnr].filetype
  local test_filetype = original_buf_option
  local observed_format_opts

  -- Select a filetype with a formatter in the captured configuration.
  if not default_config.formatters_by_ft[test_filetype] or #default_config.formatters_by_ft[test_filetype] == 0 then
    test_filetype = nil

    for filetype, configured in pairs(default_config.formatters_by_ft) do
      if #configured > 0 then
        test_filetype = filetype
        break
      end
    end
  end

  check(test_filetype ~= nil, "At least one filetype has a formatter for the :Format smoke test")

  local format_ok, format_err = xpcall(function()
    vim.bo[test_bufnr].filetype = test_filetype

    conform.list_formatters_to_run = function()
      return { { name = "smoke-test-formatter" } }
    end

    conform.format = function(opts)
      observed_format_opts = opts
    end

    formatting.format()
  end, debug.traceback)

  -- Restore stubs and buffer options regardless of the callback result.
  conform.list_formatters_to_run = original_list_formatters
  conform.format = original_format
  vim.notify = original_notify
  vim.bo[test_bufnr].filetype = original_buf_option

  if not format_ok then
    error(format_err, 0)
  end

  check(type(observed_format_opts) == "table", ":Format invokes Conform formatting")
  check_equal(observed_format_opts.bufnr, test_bufnr, ":Format targets the current buffer")
  check_equal(observed_format_opts.async, true, ":Format uses asynchronous formatting")
  check_equal(observed_format_opts.lsp_format, "never", ":Format disables LSP formatting")

  print("PASS Stage 11 formatting and linting")
end

local function check_stage12_workflows()
  -- Stage 12 configuration modules must load during startup.
  check(package.loaded["plugins.gitsigns"] ~= nil, "Gitsigns configuration module was loaded")
  check(package.loaded["plugins.project"] ~= nil, "project.nvim configuration module was loaded")
  check(package.loaded["plugins.mini-sessions"] ~= nil, "mini.sessions configuration module was loaded")

  -- Gitsigns must be available, and its buffer-local mappings must be exposed
  -- through the central keymap module. Actual buffer attachment is verified
  -- interactively because this smoke test does not require a Git buffer.
  local gitsigns_ok, gitsigns = pcall(require, "gitsigns")
  check(gitsigns_ok and type(gitsigns) == "table", "Gitsigns API is available")

  local keymaps = package.loaded["config.keymaps"]
  check(type(keymaps) == "table", "central keymap module is available")
  if type(keymaps) == "table" then
    check(type(keymaps.gitsigns) == "function", "central keymaps expose Gitsigns mappings")
  end

  -- Verify project.nvim's public root API and user-facing command.
  local project_ok, project = pcall(require, "project")
  check(project_ok and type(project) == "table", "project.nvim API is available")
  if project_ok and type(project) == "table" then
    check(type(project.get_project_root) == "function", "project root API is available")
  end
  check_equal(vim.fn.exists(":Project"), 2, "project.nvim command registration")

  -- Verify mini.sessions is available and sessions remain explicit opt-in.
  local sessions = _G.MiniSessions
  check(type(sessions) == "table", "MiniSessions API is available")
  if type(sessions) == "table" then
    check(type(sessions.select) == "function", "MiniSessions selection API is available")
    check(type(sessions.config) == "table", "MiniSessions configuration is available")
    if type(sessions.config) == "table" then
      check_equal(sessions.config.autoread, false, "automatic session reading is disabled")
      check_equal(sessions.config.autowrite, false, "automatic session writing is disabled")
    end
  end

  -- Session operations are mapped centrally and include discoverable descriptions.
  local mappings = {
    { mode = "n", lhs = "<leader>qs", desc = "Session: Restore" },
    { mode = "n", lhs = "<leader>qw", desc = "Session: Save" },
    { mode = "n", lhs = "<leader>qd", desc = "Session: Delete" },
  }

  for _, expected in ipairs(mappings) do
    check_mapping(expected.mode, expected.lhs, expected.desc, "Stage 12 sessions")
  end

  print("PASS Stage 12 Git, project, and session registration")
end

local function check_stage09_lsp()
  -- The plugin declaration must have been loaded during startup.
  check(package.loaded["plugins.lsp"] ~= nil, "plugins.lsp module was loaded")
  check(package.loaded["plugins.lazydev"] ~= nil, "plugins.lazydev module was loaded")

  local lazydev = package.loaded["lazydev"]

  check(type(lazydev) == "table", "lazydev module is available")

  -- The project-local language registry and Lua pack must be loaded.
  check(package.loaded["langs"] ~= nil, "language-pack registry was loaded")
  check(package.loaded["langs.lua"] ~= nil, "Lua language pack was loaded")

  local langs = package.loaded["langs"]

  check(type(langs) == "table" and type(langs.setup) == "function", "language registry exposes setup()")

  local lua_pack = package.loaded["langs.lua"]

  check(type(lua_pack) == "table" and type(lua_pack.setup) == "function", "Lua language pack exposes setup()")

  -- The server definition must be available through Neovim's native LSP API.
  local lua_ls = vim.lsp.config.lua_ls

  check(type(lua_ls) == "table", "effective lua_ls configuration exists")
  check(type(lua_ls.cmd) == "table", "lua_ls command is configured")
  check_equal(lua_ls.cmd[1], "lua-language-server", "lua_ls executable command")

  check(type(lua_ls.filetypes) == "table", "lua_ls filetypes are configured")

  local supports_lua = false

  for _, filetype in ipairs(lua_ls.filetypes) do
    if filetype == "lua" then
      supports_lua = true
      break
    end
  end

  check(supports_lua, "lua_ls supports Lua buffers")

  local settings = lua_ls.settings

  check(type(settings) == "table", "lua_ls settings exist")
  check(type(settings.Lua) == "table", "lua_ls Lua settings exist")

  check_equal(settings.Lua.runtime.version, "LuaJIT", "lua_ls runtime")
  check_equal(settings.Lua.diagnostics.globals[1], "vim", "lua_ls Neovim global")
  check_equal(settings.Lua.workspace.checkThirdParty, false, "lua_ls third-party workspace checks")
  check_equal(settings.Lua.telemetry.enable, false, "lua_ls telemetry")

  check(vim.lsp.is_enabled("lua_ls"), "lua_ls is enabled through the native LSP API")

  -- Shared LSP behavior must be registered independently of language packs.
  check(package.loaded["config.lsp"] ~= nil, "shared LSP configuration was loaded")

  local lsp_autocmds = vim.api.nvim_get_autocmds({
    group = "nvim_config_lsp",
    event = "LspAttach",
  })

  check(#lsp_autocmds >= 1, "shared LspAttach autocommand is registered")

  -- LSP mappings are centrally defined and can be installed per attached buffer.
  local keymaps = package.loaded["config.keymaps"]

  check(type(keymaps) == "table", "config.keymaps module is available")
  check(type(keymaps.lsp) == "function", "config.keymaps exposes the LSP mapping function")

  print("PASS Stage 09 LSP and language-pack configuration")
end

local function check_stage10_completion()
  -- Stage 10 configuration modules must be loaded.
  check(package.loaded["plugins.blink-cmp"] ~= nil, "Blink configuration module was loaded")
  check(package.loaded["plugins.friendly-snippets"] ~= nil, "friendly-snippets configuration module was loaded")
  check(package.loaded["plugins.mini-pairs"] ~= nil, "mini.pairs configuration module was loaded")

  -- Verify Blink's public completion API.
  local blink = package.loaded["blink.cmp"]

  check(type(blink) == "table", "blink.cmp module is available")

  if type(blink) ~= "table" then
    return
  end

  check(type(blink.show) == "function", "Blink completion menu API is available")
  check(type(blink.accept) == "function", "Blink completion acceptance API is available")
  check(type(blink.snippet_active) == "function", "Blink snippet-state API is available")

  -- Verify Neovim's native snippet expansion and navigation APIs.
  check(type(vim.snippet) == "table", "native vim.snippet API is available")
  check(type(vim.snippet.expand) == "function", "native snippet expansion API is available")
  check(type(vim.snippet.jump) == "function", "native snippet navigation API is available")
  check(type(vim.snippet.active) == "function", "native snippet activity API is available")

  -- Verify friendly-snippets is registered and active in vim.pack.
  local friendly_snippets

  for _, plugin in ipairs(vim.pack.get()) do
    if plugin.spec.name == "friendly-snippets" then
      friendly_snippets = plugin
      break
    end
  end

  check(type(friendly_snippets) == "table", "friendly-snippets is registered with vim.pack")

  if type(friendly_snippets) == "table" then
    check_equal(friendly_snippets.active, true, "friendly-snippets active state")
    check(vim.fn.isdirectory(friendly_snippets.path) == 1, "friendly-snippets installation directory exists")
  end

  -- Verify mini.pairs is loaded and its Insert-mode mappings exist.
  local mini_pairs = package.loaded["mini.pairs"]

  check(type(mini_pairs) == "table", "mini.pairs module is available")
  check(type(mini_pairs.setup) == "function", "mini.pairs setup API is available")

  check_mapping("i", "(", nil, "mini.pairs opening parenthesis")
  check_mapping("i", "[", nil, "mini.pairs opening bracket")
  check_mapping("i", "{", nil, "mini.pairs opening brace")

  print("PASS Stage 10 completion, snippets, and pairing")
end

local function main()
  local root = vim.fn.getcwd()
  local version = vim.version()

  check(vim.fn.has("nvim-0.12") == 1, "Neovim 0.12 or newer is required")

  -- Required configuration modules.
  check(package.loaded["config.options"] ~= nil, "config.options was loaded")
  check(package.loaded["config.keymaps"] ~= nil, "config.keymaps was loaded")
  check(package.loaded["config.autocmds"] ~= nil, "config.autocmds was loaded")

  -- Required plugin modules.
  check(package.loaded["catppuccin"] ~= nil, "catppuccin module was loaded")
  check(package.loaded["mini.icons"] ~= nil, "mini.icons module was loaded")
  check(package.loaded["which-key"] ~= nil, "which-key module was loaded")
  check(package.loaded["snacks"] ~= nil, "Snacks module was loaded")
  check(package.loaded["fzf-lua"] ~= nil, "fzf-lua module was loaded")
  check(package.loaded["flash"] ~= nil, "flash.nvim module was loaded")
  check(package.loaded["mini.ai"] ~= nil, "mini.ai module was loaded")
  check(package.loaded["mini.surround"] ~= nil, "mini.surround module was loaded")
  check(package.loaded["mini.move"] ~= nil, "mini.move module was loaded")
  check(package.loaded["dial.map"] ~= nil, "dial.nvim mapping module was loaded")

  -- Stage 05 colorscheme.
  check_equal(vim.g.colors_name, "catppuccin-mocha", "active colorscheme")

  -- Stage 06 plugins.
  check_stage06_plugins()

  -- Stage 07 navigation and editing plugins.
  check_stage07_plugins()

  -- Stage 09 LSP and language-pack integration.
  check_stage09_lsp()

  -- Stage 10 completion, snippets, and pairing.
  check_stage10_completion()

  -- Stage 11 formatter integration.
  check_stage11_formatting()

  -- Stage 12 Git, project-root, and session workflows.
  check_stage12_workflows()

  -- Leader keys.
  check_equal(vim.g.mapleader, " ", "mapleader")
  check_equal(vim.g.maplocalleader, "\\", "maplocalleader")

  -- Window-local options.
  check_equal(vim.wo.number, true, "number")
  check_equal(vim.wo.relativenumber, true, "relativenumber")
  check_equal(vim.wo.cursorline, true, "cursorline")
  check_equal(vim.wo.wrap, false, "wrap")

  -- Buffer-local options.
  check_equal(vim.bo.expandtab, true, "expandtab")
  check_equal(vim.bo.shiftwidth, 2, "shiftwidth")
  check_equal(vim.bo.tabstop, 2, "tabstop")
  check_equal(vim.bo.softtabstop, 2, "softtabstop")

  -- Global options.
  check_equal(vim.o.ignorecase, true, "ignorecase")
  check_equal(vim.o.smartcase, true, "smartcase")
  check_equal(vim.o.splitright, true, "splitright")
  check_equal(vim.o.splitbelow, true, "splitbelow")
  check_equal(vim.o.signcolumn, "yes", "signcolumn")
  check_equal(vim.o.showmode, false, "showmode")
  check_equal(vim.o.termguicolors, true, "termguicolors")
  check_equal(vim.o.updatetime, 250, "updatetime")
  check_equal(vim.o.timeoutlen, 400, "timeoutlen")
  check_equal(vim.o.undofile, true, "undofile")

  -- Native statusline.
  check_equal(vim.o.laststatus, 3, "native statusline visibility")
  check_equal(vim.o.statusline, "%f %m%r%h%w %= %y %l:%c %p%%", "native statusline format")

  -- Windows shell resolution.
  if vim.fn.has("win32") == 1 then
    local windows_shell = vim.env.ComSpec

    if windows_shell and vim.fn.executable(windows_shell) == 1 then
      check_equal(vim.o.shell, windows_shell, "Windows shell path")
    end
  end

  -- Native keymap contract.
  local keymaps = {
    { mode = "n", lhs = "<C-s>", desc = "Save file" },
    { mode = "i", lhs = "<C-s>", desc = "Save file" },
    { mode = "v", lhs = "<C-s>", desc = "Save file" },
    { mode = "n", lhs = "<C-h>", desc = "Focus left window" },
    { mode = "n", lhs = "<C-j>", desc = "Focus lower window" },
    { mode = "n", lhs = "<C-k>", desc = "Focus upper window" },
    { mode = "n", lhs = "<C-l>", desc = "Focus right window" },
    { mode = "n", lhs = "<leader>sv", desc = "Split window vertically" },
    { mode = "n", lhs = "<leader>sh", desc = "Split window horizontally" },
    { mode = "n", lhs = "<leader>se", desc = "Equalize window sizes" },
    { mode = "n", lhs = "<leader>sx", desc = "Close current window" },
  }

  for _, expected in ipairs(keymaps) do
    check_mapping(expected.mode, expected.lhs, expected.desc, "Native")
  end

  -- Autocommand contract.
  local autocmds = vim.api.nvim_get_autocmds({
    group = "nvim_config",
  })

  check(#autocmds >= 3, "expected at least three nvim_config autocommands")

  local required_events = {
    TextYankPost = false,
    BufReadPost = false,
    VimResized = false,
  }

  for _, autocmd in ipairs(autocmds) do
    if required_events[autocmd.event] ~= nil then
      required_events[autocmd.event] = true
    end
  end

  for event, found in pairs(required_events) do
    check(found, "autocommand event exists: " .. event)
  end

  -- Native diagnostics baseline.
  local diagnostics = vim.diagnostic.config()

  check_equal(diagnostics.virtual_text, true, "diagnostic virtual_text")
  check_equal(diagnostics.signs, true, "diagnostic signs")
  check_equal(diagnostics.underline, true, "diagnostic underline")
  check_equal(diagnostics.update_in_insert, false, "diagnostic update_in_insert")
  check_equal(diagnostics.severity_sort, true, "diagnostic severity_sort")

  -- Native terminal workflow.
  local terminal_escape = vim.fn.maparg("<Esc><Esc>", "t", false, true)

  check(type(terminal_escape) == "table" and next(terminal_escape) ~= nil, "terminal escape mapping exists")
  check_equal(terminal_escape.rhs, "<C-\\><C-n>", "terminal escape mapping rhs")
  check_equal(terminal_escape.desc, "Exit terminal mode", "terminal escape mapping description")

  -- Stage 04 native workflow tests.
  check_native_grep()
  check_native_commenting()

  -- Required modules must fail visibly and stop later module loading.
  check_module_failure_contract(root)

  print(string.format("PASS nvim-config smoke test on Neovim %d.%d.%d", version.major, version.minor, version.patch))
end

local ok, err = pcall(main)

if not ok then
  io.stderr:write(tostring(err) .. "\n")
  vim.cmd("cquit 1")
end

vim.cmd("qa!")
