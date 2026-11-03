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

local function has_luarc(dir)
  if not dir then
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
      local root_dir = config.root_dir

      -- Fall back to the initialization workspace folder.
      if not root_dir and params.workspaceFolders then
        local folder = params.workspaceFolders[1]

        if folder then
          root_dir = vim.uri_to_fname(folder.uri)
        end
      end

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
