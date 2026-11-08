-- Stage 09: Lua language pack.
-- LuaLS is an external executable; Neovim owns LSP configuration and activation.
-- Stage 11: Formatter metadata is declared by the language pack.
-- Tree-sitter parser ownership is declared by filetype.

local M = {
  formatters = {
    lua = { "stylua" },
  },

  parser_by_filetype = {
    lua = "lua",
  },
}

-- ============================================================
-- Project Configuration
-- ============================================================

local function is_json_null(value)
  return value == nil or value == vim.NIL
end

local function has_luarc(dir)
  if is_json_null(dir) or type(dir) ~= "string" or dir == "" then
    return false
  end

  for _, name in ipairs({ ".luarc.json", ".luarc.jsonc" }) do
    local path = vim.fs.joinpath(dir, name)

    if vim.uv.fs_stat(path) then
      return true
    end
  end

  return false
end

-- ============================================================
-- LuaLS Settings
-- ============================================================

local function lua_settings()
  local library = {
    "${3rd}/luv/library",
  }

  if vim.env.VIMRUNTIME then
    table.insert(library, vim.env.VIMRUNTIME)
  end

  return {
    Lua = {
      runtime = {
        version = "LuaJIT",
        path = {
          "lua/?.lua",
          "lua/?/init.lua",
        },
      },

      completion = {
        callSnippet = "Replace",
      },

      diagnostics = {
        globals = { "vim" },
        unusedLocalExclude = { "_*" },
      },

      format = {
        enable = false,
      },

      hint = {
        enable = true,
        setType = true,
      },

      workspace = {
        checkThirdParty = false,
        library = library,
      },

      telemetry = {
        enable = false,
      },
    },
  }
end

-- ============================================================
-- Workspace Resolution
-- ============================================================

local function workspace_root(params, config)
  local root_dir = config.root_dir

  if not is_json_null(root_dir) and type(root_dir) == "string" and root_dir ~= "" then
    return root_dir
  end

  local folders = params.workspaceFolders

  if is_json_null(folders) or type(folders) ~= "table" then
    return nil
  end

  local folder = folders[1]

  if is_json_null(folder) or type(folder) ~= "table" then
    return nil
  end

  local uri = folder.uri

  if is_json_null(uri) or type(uri) ~= "string" or uri == "" then
    return nil
  end

  local ok, root = pcall(vim.uri_to_fname, uri)

  if not ok or type(root) ~= "string" or root == "" then
    return nil
  end

  return root
end

-- ============================================================
-- Setup
-- ============================================================

function M.setup()
  -- LuaLS is optional at runtime.
  if vim.fn.executable("lua-language-server") ~= 1 then
    return
  end

  vim.lsp.config("lua_ls", {
    -- cmd, filetypes, and root markers come from nvim-lspconfig.

    before_init = function(params, config)
      local root_dir = workspace_root(params, config)

      -- Allow project-specific configuration to take precedence.
      if has_luarc(root_dir) then
        return
      end

      config.settings = vim.tbl_deep_extend("force", config.settings or {}, lua_settings())
    end,
  })

  vim.lsp.enable("lua_ls")
end

return M
