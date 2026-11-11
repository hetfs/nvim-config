-- Stage 08: Tree-sitter.
-- Keep plugin loading eager and install parsers automatically on demand.
-- Language-pack activation and parser mappings come from the language registry.

vim.pack.add({
  {
    src = "https://github.com/nvim-treesitter/nvim-treesitter",
    name = "nvim-treesitter",
  },
})

-- On Windows, expose the built-in tar executable when it is missing from PATH.
if vim.fn.has("win32") == 1 and vim.fn.executable("tar") == 0 then
  local windir = vim.env.WINDIR

  if windir and windir ~= "" then
    local tar = vim.fs.joinpath(windir, "System32", "tar.exe")

    if vim.fn.executable(tar) == 1 then
      local dir = vim.fs.dirname(tar)
      vim.env.PATH = dir .. ";" .. (vim.env.PATH or "")
    end
  end
end

-- On Windows, use GCC for parser builds when CC is not already configured.
if vim.fn.has("win32") == 1 and (not vim.env.CC or vim.env.CC == "") then
  local gcc = vim.fn.exepath("gcc")

  if gcc ~= "" then
    vim.env.CC = gcc
  end
end

-- Configure the parser and query installation directory.
require("nvim-treesitter").setup({
  install_dir = vim.fn.stdpath("data") .. "/site",
})

-- Obtain Tree-sitter metadata from enabled language packs.
-- Disabled packs do not contribute Tree-sitter support.
local langs = require("langs")

local filetype_parsers = langs.collect("parser_by_filetype")
local parser_dependencies = langs.collect("parser_dependencies_by_filetype")

-- Validate primary parser mappings.
for filetype, parser in pairs(filetype_parsers) do
  assert(
    type(filetype) == "string" and filetype ~= "",
    "Tree-sitter filetype mappings must use non-empty string keys"
  )

  assert(
    type(parser) == "string" and parser ~= "",
    string.format("Tree-sitter parser mapping for '%s' must be a non-empty string", tostring(filetype))
  )
end

-- Validate additional parser dependencies.
for filetype, dependencies in pairs(parser_dependencies) do
  assert(
    type(filetype) == "string" and filetype ~= "",
    "Tree-sitter dependency mappings must use non-empty string keys"
  )

  assert(
    filetype_parsers[filetype] ~= nil,
    string.format("Tree-sitter dependencies for '%s' require a primary parser mapping", filetype)
  )

  assert(
    type(dependencies) == "table" and #dependencies > 0,
    string.format("Tree-sitter dependencies for '%s' must be a non-empty list", filetype)
  )

  local count = 0

  for index, parser in pairs(dependencies) do
    assert(
      type(index) == "number" and index >= 1 and math.floor(index) == index,
      string.format("Tree-sitter dependencies for '%s' must use sequential numeric indices", filetype)
    )

    assert(
      type(parser) == "string" and parser ~= "",
      string.format("Tree-sitter dependency at index %s for '%s' must be a non-empty string", tostring(index), filetype)
    )

    assert(
      parser ~= filetype_parsers[filetype],
      string.format("Tree-sitter dependency '%s' for '%s' duplicates its primary parser", parser, filetype)
    )

    count = count + 1
  end

  assert(
    count == #dependencies,
    string.format("Tree-sitter dependencies for '%s' must not contain missing list entries", filetype)
  )
end

-- Register parser mappings with Neovim's native Tree-sitter API.
-- This supports filetypes whose names differ from their parser names.
-- Examples: plaintex -> latex, jsonc -> json, typescriptreact -> tsx.
for filetype, parser in pairs(filetype_parsers) do
  vim.treesitter.language.register(parser, filetype)
end

-- Track installations to avoid duplicate requests.
-- Each waiting buffer records whether the parser should enable highlighting.
local pending = {}

-- Check for the actual parser binary and verify that Neovim can load it.
local function parser_available(parser)
  local files = vim.api.nvim_get_runtime_file("parser/" .. parser .. ".*", false)

  if #files == 0 then
    return false
  end

  local ok, result = pcall(vim.treesitter.language.add, parser)

  -- pcall() only indicates whether the function raised an exception.
  -- A nil or false result means the parser was not loaded successfully.
  return ok and result ~= nil and result ~= false
end

local function start_highlighting(buf, parser)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  -- The buffer may have changed filetype while installation was running.
  local filetype = vim.bo[buf].filetype

  if filetype_parsers[filetype] ~= parser then
    return
  end

  local ok, err = pcall(vim.treesitter.start, buf, parser)

  if not ok then
    vim.notify(
      string.format("Could not start Tree-sitter for '%s': %s", parser, err),
      vim.log.levels.WARN,
      { title = "Tree-sitter" }
    )
  end
end

local function wait_for_parser(parser, state)
  vim.defer_fn(function()
    -- Ignore callbacks belonging to a completed or replaced installation.
    if pending[parser] ~= state then
      return
    end

    if parser_available(parser) then
      pending[parser] = nil

      for buf, should_highlight in pairs(state.buffers) do
        if should_highlight then
          start_highlighting(buf, parser)
        end
      end

      return
    end

    state.attempts = state.attempts + 1

    if state.attempts >= 600 then
      pending[parser] = nil

      vim.notify(
        string.format(
          "Installation of the '%s' parser did not complete within 5 minutes. Check :messages and the nvim-treesitter installation logs.",
          parser
        ),
        vim.log.levels.WARN,
        { title = "Tree-sitter" }
      )

      return
    end

    wait_for_parser(parser, state)
  end, 500)
end

local function ensure_parser(buf, parser, should_highlight)
  -- Reuse an installed parser immediately.
  if parser_available(parser) then
    if should_highlight then
      start_highlighting(buf, parser)
    end

    return
  end

  -- Register buffers waiting for the same parser installation.
  if pending[parser] then
    local previous = pending[parser].buffers[buf]

    -- A primary-parser request takes precedence over a dependency request.
    pending[parser].buffers[buf] = previous == true or should_highlight

    return
  end

  local state = {
    buffers = {
      [buf] = should_highlight,
    },
    attempts = 0,
  }

  pending[parser] = state

  -- Installation runs asynchronously.
  local ok, err = pcall(function()
    require("nvim-treesitter").install({ parser })
  end)

  if not ok then
    pending[parser] = nil

    vim.notify(
      string.format("Could not install the '%s' parser: %s", parser, err),
      vim.log.levels.ERROR,
      { title = "Tree-sitter" }
    )

    return
  end

  wait_for_parser(parser, state)
end

-- Automatically install missing parsers and enable native highlighting.
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("nvim_config_treesitter", {
    clear = true,
  }),
  pattern = vim.tbl_keys(filetype_parsers),
  desc = "Install Tree-sitter parsers on demand and enable highlighting",
  callback = function(event)
    local filetype = vim.bo[event.buf].filetype
    local parser = filetype_parsers[filetype]

    if not parser then
      return
    end

    -- Install the primary parser and enable highlighting when available.
    ensure_parser(event.buf, parser, true)

    -- Install additional parsers without starting them on this buffer.
    for _, dependency in ipairs(parser_dependencies[filetype] or {}) do
      ensure_parser(event.buf, dependency, false)
    end
  end,
})

