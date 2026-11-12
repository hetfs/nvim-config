-- Stage 10: Completion engine.
--
-- Use Blink 1.x with Neovim's native vim.pack.
-- Completion is triggered manually with <C-Space>.
-- Neovim's native LSP client remains responsible for language servers.

vim.pack.add({
  {
    src = "https://github.com/Saghen/blink.cmp",
    name = "blink.cmp",
    version = vim.version.range("1.*"),
  },
}, { load = true })

local blink = require("blink.cmp")
local icons = require("mini.icons")

-- Resolve completion icons through mini.icons.
-- Path completions use filesystem icons.
-- Other completion sources use LSP-kind icons.
local function get_completion_icon(ctx)
  if ctx.source_name == "Path" then
    local item_type = (ctx.item.data or {}).type

    if item_type then
      local generic_types = {
        link = true,
        socket = true,
        fifo = true,
        char = true,
        block = true,
        unknown = true,
      }

      local icon, highlight = icons.get(
        generic_types[item_type] and "os" or item_type,
        generic_types[item_type] and "" or ctx.label
      )

      if icon then
        return icon, highlight
      end
    end
  end

  return icons.get("lsp", ctx.kind)
end

blink.setup({
  -- Explicit completion and snippet-navigation mappings.
  keymap = {
    preset = "none",

    -- Manually open completion and documentation.
    ["<C-space>"] = {
      "show",
      "show_documentation",
      "hide_documentation",
    },

    -- Navigate completion candidates.
    ["<C-n>"] = { "select_next", "fallback" },
    ["<C-p>"] = { "select_prev", "fallback" },

    -- Accept the selected completion candidate.
    ["<C-y>"] = { "accept", "fallback" },

    -- Close the completion menu.
    ["<C-e>"] = { "hide", "fallback" },

    -- Navigate native snippet placeholders.
    ["<Tab>"] = { "snippet_forward", "fallback" },
    ["<S-Tab>"] = { "snippet_backward", "fallback" },
  },

  -- Use monochrome Nerd Font icons.
  appearance = {
    nerd_font_variant = "mono",
  },

  completion = {
    list = {
      selection = {
        -- Avoid preselection while a forward snippet placeholder is active.
        preselect = function(ctx)
          return not blink.snippet_active({
            direction = 1,
          })
        end,

        -- Require explicit acceptance.
        auto_insert = false,
      },
    },

    menu = {
      -- Completion is manually triggered in Insert mode.
      auto_show = false,
      border = "rounded",

      draw = {
        treesitter = { "lsp" },

        columns = {
          { "kind_icon" },
          { "label", "label_description", gap = 1 },
          { "kind" },
        },

        components = {
          kind_icon = {
            text = function(ctx)
              local icon = get_completion_icon(ctx)
              return icon
            end,

            highlight = function(ctx)
              local _, highlight = get_completion_icon(ctx)
              return highlight
            end,
          },

          kind = {
            highlight = function(ctx)
              local _, highlight = get_completion_icon(ctx)
              return highlight
            end,
          },
        },
      },
    },

    documentation = {
      auto_show = true,
      auto_show_delay_ms = 300,

      window = {
        border = "rounded",
      },
    },

    ghost_text = {
      enabled = false,
    },
  },

  -- Function signature information.
  signature = {
    enabled = true,

    window = {
      border = "rounded",
    },
  },

  sources = {
    -- Default Insert-mode completion sources.
    default = {
      "lsp",
      "path",
      "snippets",
      "buffer",
      "omni",
    },

    -- Extend the default sources for Lua files.
    per_filetype = {
      lua = {
        inherit_defaults = true,
        "lazydev",
      },
    },

    providers = {
      -- Neovim and Lua library completions.
      lazydev = {
        name = "LazyDev",
        module = "lazydev.integrations.blink",
        score_offset = 100,
      },
    },
  },

  -- Use Neovim's native snippet engine.
  snippets = {
    preset = "default",
  },

  -- Keep command-line completion independent of Insert mode.
  cmdline = {
    enabled = true,

    keymap = {
      preset = "inherit",
    },

    sources = {
      "buffer",
      "cmdline",
    },

    completion = {
      menu = {
        auto_show = true,
      },
    },
  },

  -- Prefer the Rust fuzzy matcher.
  fuzzy = {
    implementation = "prefer_rust_with_warning",
  },
})
