-- Stage 13: SQL language pack.
-- SQLS uses native Neovim LSP configuration and activation.
-- Formatter and parser metadata are consumed by shared integrations.

local M = {
  formatters = {
    sql = { "sql_formatter" },
  },

  parser_by_filetype = {
    sql = "sql",
  },
}

local VALID_DIALECTS = {
  postgresql = true,
  mysql = true,
  sqlite = true,
}

local DEFAULT_DIALECT = "postgresql"
local PROJECT_CONFIG = ".sql-formatter.json"

local warned = {}

-- ============================================================
-- Warnings and Dialect Validation
-- ============================================================

local function warn_once(key, message)
  if warned[key] then
    return
  end

  warned[key] = true

  vim.notify(message, vim.log.levels.WARN, {
    title = "SQL",
  })
end

local function validate_dialect(value, source)
  if value == nil then
    return nil
  end

  if type(value) ~= "string" then
    warn_once("invalid-type:" .. source, ("SQL dialect from %s must be a string."):format(source))

    return nil
  end

  local dialect = value:lower()

  if VALID_DIALECTS[dialect] then
    return dialect
  end

  warn_once("invalid-dialect:" .. source .. ":" .. dialect, ("Invalid SQL dialect '%s' from %s."):format(dialect, source))

  return nil
end

-- ============================================================
-- Dialect Sources
-- ============================================================

local function buffer_dialect(bufnr)
  local ok, value = pcall(vim.api.nvim_buf_get_var, bufnr, "sql_dialect")

  if not ok then
    return nil
  end

  return validate_dialect(value, "b:sql_dialect")
end

local function filetype_dialect(filetype)
  local overrides = vim.g.sql_dialect_by_ft

  if overrides == nil then
    return nil
  end

  if type(overrides) ~= "table" then
    warn_once("invalid-filetype-map", "g:sql_dialect_by_ft must be a table.")

    return nil
  end

  return validate_dialect(overrides[filetype], "g:sql_dialect_by_ft")
end

local function project_config_path(bufnr)
  local filename = vim.api.nvim_buf_get_name(bufnr)
  local start_dir

  if filename ~= "" then
    start_dir = vim.fs.dirname(filename)
  else
    start_dir = vim.fn.getcwd()
  end

  if not start_dir or start_dir == "" then
    return nil
  end

  local matches = vim.fs.find(PROJECT_CONFIG, {
    path = start_dir,
    upward = true,
    type = "file",
  })

  return matches[1]
end

local function project_dialect(bufnr)
  local path = project_config_path(bufnr)

  if not path then
    return nil
  end

  local ok, contents = pcall(vim.fn.readfile, path)

  if not ok then
    warn_once("project-config-read:" .. path, ("Unable to read SQL Formatter configuration: %s"):format(path))

    return nil
  end

  local decoded, config = pcall(vim.json.decode, table.concat(contents, "\n"))

  if not decoded or type(config) ~= "table" then
    warn_once("project-config-json:" .. path, ("Invalid JSON in SQL Formatter configuration: %s"):format(path))

    return nil
  end

  return validate_dialect(config.language, path)
end

-- ============================================================
-- Dialect Resolution
-- ============================================================

---Resolve the SQL dialect for a buffer.
---
---Precedence:
---  1. b:sql_dialect
---  2. g:sql_dialect_by_ft[filetype]
---  3. Nearest .sql-formatter.json language
---  4. g:sql_dialect
---  5. postgresql
---
---@param bufnr? integer
---@return string
function M.resolve_dialect(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  local dialect = buffer_dialect(bufnr)

  if dialect then
    return dialect
  end

  local filetype = vim.bo[bufnr].filetype

  if filetype ~= "" then
    dialect = filetype_dialect(filetype)

    if dialect then
      return dialect
    end
  end

  dialect = project_dialect(bufnr)

  if dialect then
    return dialect
  end

  dialect = validate_dialect(vim.g.sql_dialect, "g:sql_dialect")

  if dialect then
    return dialect
  end

  return DEFAULT_DIALECT
end

-- ============================================================
-- SQLS Workspace Resolution
-- ============================================================

---Resolve the SQLS workspace root.
---
---Git repositories use their Git root.
---Standalone SQL files use their containing directory.
---Unnamed buffers use the current working directory.
---
---@param bufnr integer
---@return string?
function M.workspace_root(bufnr)
  local filename = vim.api.nvim_buf_get_name(bufnr)

  if filename ~= "" then
    local directory = vim.fs.dirname(filename)
    local git_root = vim.fs.root(directory, { ".git" })

    return git_root or directory
  end

  local cwd = vim.fn.getcwd()

  if cwd ~= "" then
    return cwd
  end

  return nil
end

-- ============================================================
-- Setup
-- ============================================================

function M.setup()
  -- SQLFluff owns static analysis and starts independently of SQLS.
  require("langs.sql.lint").setup()

  -- SQLS owns language-server functionality.
  if vim.fn.executable("sqls") ~= 1 then
    return
  end

  vim.lsp.config("sqls", {
    root_dir = function(bufnr, on_dir)
      local root = M.workspace_root(bufnr)

      if root then
        on_dir(root)
      end
    end,
  })

  vim.lsp.enable("sqls")
end

return M
