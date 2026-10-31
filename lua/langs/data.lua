-- Stage 13: Data-language pack.
-- Neovim owns LSP configuration and activation.
-- Conform owns formatting through the shared formatter registry.
-- jq execution is handled natively through vim.system().

local M = {
  formatters = {
    -- YAML and its supported variants.
    yaml = { "prettier" },
    ["yaml.docker-compose"] = { "prettier" },
    ["yaml.ansible"] = { "prettier" },
    ["yaml.gitlab"] = { "prettier" },
    ["yaml.helm-values"] = { "prettier" },

    -- JSON formats.
    json = { "prettier" },
    jsonc = { "prettier" },
    json5 = { "prettier" },

    -- TOML.
    toml = { "taplo" },
  },

  filetypes = {
    yaml = {
      "yaml",
      "yaml.docker-compose",
      "yaml.ansible",
      "yaml.gitlab",
      "yaml.helm-values",
    },

    json = {
      "json",
      "jsonc",
      "json5",
    },

    jq = {
      "jq",
    },

    toml = {
      "toml",
    },
  },

  parsers = {
    "yaml",
    "json",
    "json5",
    "jq",
    "toml",
  },

  -- Server names consumed by vim.lsp.enable().
  servers = {
    "yamlls",
    "jsonls",
    "jqls",
    "taplo",
  },

  -- A server is enabled only when its executable is available.
  executables = {
    yamlls = "yaml-language-server",
    jsonls = "vscode-json-language-server",
    jqls = "jq-lsp",
    taplo = "taplo",
  },
}

local function notify(message, level)
  vim.notify(message, level, {
    title = "jq",
  })
end

-- Configure a server when custom settings are provided.
-- Enable it only when its executable is available.
local function enable(server, config)
  local executable = assert(M.executables[server], string.format("No executable declared for data server '%s'", server))

  if config then
    vim.lsp.config(server, config)
  end

  if vim.fn.executable(executable) == 1 then
    vim.lsp.enable(server)
  end
end

local function get_input(bufnr, line1, line2)
  if line1 and line2 then
    return vim.api.nvim_buf_get_lines(bufnr, line1 - 1, line2, false)
  end

  return vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
end

-- Keep one reusable scratch buffer across jq executions.
local result_buf

local function get_result_buffer()
  if result_buf and vim.api.nvim_buf_is_valid(result_buf) then
    return result_buf
  end

  result_buf = vim.api.nvim_create_buf(false, true)

  vim.bo[result_buf].buftype = "nofile"
  vim.bo[result_buf].bufhidden = "hide"
  vim.bo[result_buf].swapfile = false

  vim.keymap.set("n", "q", "<cmd>close<CR>", {
    buffer = result_buf,
    silent = true,
    desc = "Close jq result",
  })

  return result_buf
end

local function split_output(output)
  -- Remove the final newline added by jq, not meaningful blank lines.
  if output:sub(-1) == "\n" then
    output = output:sub(1, -2)
  end

  return vim.split(output, "\n", {
    plain = true,
    trimempty = false,
  })
end

local function show_output(source_win, output, raw)
  if not vim.api.nvim_win_is_valid(source_win) then
    notify("The source window is no longer available.", vim.log.levels.WARN)
    return
  end

  local bufnr = get_result_buffer()
  local lines = split_output(output)

  vim.bo[bufnr].modifiable = true
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.bo[bufnr].filetype = raw and "text" or "json"
  vim.bo[bufnr].modifiable = false

  -- Reuse the result window when it is already visible.
  local result_win = vim.fn.bufwinid(bufnr)

  if result_win == -1 then
    -- Otherwise open the reusable result buffer in a vertical split.
    vim.api.nvim_win_call(source_win, function()
      vim.cmd("botright vsplit")
      vim.api.nvim_win_set_buf(0, bufnr)
    end)
  end

  -- Keep the source buffer active for subsequent jq executions.
  if vim.api.nvim_win_is_valid(source_win) then
    vim.api.nvim_set_current_win(source_win)
  end
end

function M.run(filter, opts)
  opts = opts or {}

  if vim.fn.executable("jq") ~= 1 then
    notify("jq executable was not found in PATH.", vim.log.levels.ERROR)
    return
  end

  filter = vim.trim(filter or "")

  if filter == "" then
    filter = "."
  end

  local source_buf = vim.api.nvim_get_current_buf()
  local source_win = vim.api.nvim_get_current_win()
  local input = get_input(source_buf, opts.line1, opts.line2)
  local stdin = table.concat(input, "\n")

  if #input > 0 then
    stdin = stdin .. "\n"
  end

  local command = { "jq" }

  if opts.raw then
    command[#command + 1] = "-r"
  end

  command[#command + 1] = filter

  vim.system(command, {
    stdin = stdin,
    text = true,
  }, function(result)
    vim.schedule(function()
      if result.code ~= 0 then
        local message = vim.trim(result.stderr or "")

        if message == "" then
          message = string.format("jq exited with code %s", tostring(result.code))
        end

        notify(message, vim.log.levels.ERROR)
        return
      end

      show_output(source_win, result.stdout or "", opts.raw)
    end)
  end)
end

function M.run_prompt()
  vim.ui.input({
    prompt = "jq filter: ",
    default = ".",
  }, function(filter)
    if filter ~= nil then
      M.run(filter)
    end
  end)
end

function M.setup()
  -- YAML language server.
  enable("yamlls", {
    filetypes = {
      "yaml",
      "yaml.docker-compose",
      "yaml.ansible",
      "yaml.gitlab",
      "yaml.helm-values",
    },

    settings = {
      redhat = {
        telemetry = {
          enabled = false,
        },
      },

      yaml = {
        validate = true,

        -- Formatting is handled by Conform.
        format = {
          enable = false,
        },

        -- SchemaStore integration is intentionally deferred.
        schemaStore = {
          enable = false,
        },
      },
    },
  })

  -- JSON language server.
  -- Supports JSON and JSONC; JSON5 LSP support is not enabled.
  enable("jsonls", {
    filetypes = {
      "json",
      "jsonc",
    },

    settings = {
      json = {
        validate = {
          enable = true,
        },

        -- Formatting is handled by Conform.
        format = {
          enable = false,
        },

        -- Schema associations are intentionally deferred.
        schemas = {},
      },
    },
  })

  -- jq language server.
  -- Server definition is provided by nvim-lspconfig.
  enable("jqls")

  -- TOML language server.
  -- Server definition is provided by nvim-lspconfig.
  enable("taplo")

  -- jq command.
  -- Use :Jq! for raw output (-r).
  vim.api.nvim_create_user_command("Jq", function(command)
    M.run(command.args, {
      line1 = command.range > 0 and command.line1 or nil,
      line2 = command.range > 0 and command.line2 or nil,
      raw = command.bang,
    })
  end, {
    nargs = "*",
    range = true,
    bang = true,
    desc = "Run jq on the current buffer or selected range",
  })
end

return M
