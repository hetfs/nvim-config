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

-- Obtain filetype-to-parser mappings from enabled language packs.
-- Disabled packs do not contribute Tree-sitter support.
local filetype_parsers = require("langs").collect("parser_by_filetype")

-- Validate the registry metadata before creating the autocmd.
for filetype, parser in pairs(filetype_parsers) do
  assert(type(filetype) == "string" and filetype ~= "", "Tree-sitter filetype mappings must use non-empty string keys")

  assert(type(parser) == "string" and parser ~= "", string.format("Tree-sitter parser mapping for '%s' must be a non-empty string", tostring(filetype)))
end

-- Track installations to avoid duplicate requests.
local pending = {}

local function parser_available(parser)
  return pcall(vim.treesitter.language.add, parser)
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
    vim.notify(string.format("Could not start Tree-sitter for '%s': %s", parser, err), vim.log.levels.WARN, { title = "Tree-sitter" })
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

      for buf in pairs(state.buffers) do
        start_highlighting(buf, parser)
      end

      return
    end

    state.attempts = state.attempts + 1

    if state.attempts >= 600 then
      pending[parser] = nil

      vim.notify(
        string.format("Installation of the '%s' parser did not complete within 5 minutes. Check :TSLog.", parser),
        vim.log.levels.WARN,
        { title = "Tree-sitter" }
      )

      return
    end

    wait_for_parser(parser, state)
  end, 500)
end

local function ensure_parser(buf, parser)
  -- Reuse an installed parser immediately.
  if parser_available(parser) then
    start_highlighting(buf, parser)
    return
  end

  -- Register buffers waiting for the same parser installation.
  if pending[parser] then
    pending[parser].buffers[buf] = true
    return
  end

  local state = {
    buffers = {
      [buf] = true,
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

    vim.notify(string.format("Could not install the '%s' parser: %s", parser, err), vim.log.levels.ERROR, { title = "Tree-sitter" })

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

    if parser then
      ensure_parser(event.buf, parser)
    end
  end,
})
