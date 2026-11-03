
-- Stage 10: Completion engine.
-- Use Blink 1.x with Neovim's native vim.pack.
-- Insert-mode completion is automatically triggered.
-- Neovim's native LSP client remains responsible for language servers.

vim.pack.add({
  {
    src = "https://github.com/Saghen/blink.cmp",
    name = "blink.cmp",
    version = vim.version.range("1.*"),
  },
}, { load = true })

-- Resolve completion icons through mini.icons.
-- Path completions use filesystem icons; other sources use LSP-kind icons.
local function get_mini_icon(ctx)
  if ctx.source_name == "Path" then
    local item_data = ctx.item.data or {}
    local item_type = item_data.type

    if item_type then
      -- Special filesystem types use the generic OS icon category.
      local is_unknown_type = vim.tbl_contains({
        "link",
        "socket",
        "fifo",
        "char",
        "block",
        "unknown",
      }, item_type)

      local icon, highlight = require("mini.icons").get(
        is_unknown_type and "os" or item_type,
        is_unknown_type and "" or ctx.label
      )

      if icon then
        return icon, highlight
      end
    end
  end

  -- Use LSP symbol-kind icons for other completion sources.
  return require("mini.icons").get("lsp", ctx.kind)
end

require("blink.cmp").setup({
  -- Define completion and snippet navigation explicitly.
  -- The none preset prevents Blink from adding default key mappings.
  keymap = {
    preset = "none",

    -- Manual completion trigger.
    -- To restore manual completion:
    -- 1. Uncomment this mapping.
    -- 2. Set completion.menu.auto_show = false below.
    --
    -- Windows Terminal currently does not transmit <C-;> reliably.
    -- Keep this disabled while using automatic completion.
    --
    -- ["<C-;>"] = {
    --   "show",
    --   "show_documentation",
    --   "hide_documentation",
    -- },

    -- Navigate completion candidates.
    -- Preserve Neovim's normal behavior when Blink cannot act.
    ["<C-n>"] = { "select_next", "fallback" },
    ["<C-p>"] = { "select_prev", "fallback" },

    -- Accept the selected candidate without interfering with ordinary y input.
    ["<C-y>"] = { "accept", "fallback" },

    -- Close the completion menu.
    ["<C-e>"] = { "hide", "fallback" },

    -- Navigate placeholders in native Neovim snippets.
    ["<Tab>"] = { "snippet_forward", "fallback" },
    ["<S-Tab>"] = { "snippet_backward", "fallback" },
  },

  -- Use monochrome Nerd Font icons for consistent alignment.
  appearance = {
    nerd_font_variant = "mono",
  },

  completion = {
    list = {
      selection = {
        -- Avoid preselecting candidates while a forward snippet
        -- placeholder is active.
        preselect = function(ctx)
          return not require("blink.cmp").snippet_active({
            direction = 1,
          })
        end,

        -- Require explicit acceptance instead of automatic insertion.
        auto_insert = false,
      },
    },

    menu = {
      -- Automatically display completion suggestions while typing.
      -- Set false when switching back to manual completion.
      auto_show = true,
      border = "rounded",

      draw = {
        -- Use Tree-sitter highlighting for LSP completion labels.
        treesitter = { "lsp" },

        -- Display the icon, completion label, description, and kind.
        columns = {
          { "kind_icon" },
          { "label", "label_description", gap = 1 },
          { "kind" },
        },

        -- Customize completion menu components.
        components = {
          kind_icon = {
            -- Display the icon returned by mini.icons.
            text = function(ctx)
              local icon = get_mini_icon(ctx)
              return icon
            end,

            -- Apply the corresponding icon highlight.
            highlight = function(ctx)
              local _, highlight = get_mini_icon(ctx)
              return highlight
            end,
          },

          kind = {
            -- Match completion-kind text to its icon highlight.
            highlight = function(ctx)
              local _, highlight = get_mini_icon(ctx)
              return highlight
            end,
          },
        },
      },
    },

    documentation = {
      -- Display documentation automatically after a short delay.
      auto_show = true,
      auto_show_delay_ms = 300,

      window = {
        border = "rounded",
      },
    },

    -- Avoid inline ghost text while completing.
    ghost_text = {
      enabled = false,
    },
  },

  -- Display function signature information when available.
  signature = {
    enabled = true,

    window = {
      border = "rounded",
    },
  },

  sources = {
    -- Completion sources available in normal Insert mode.
    default = {
      "lsp",
      "path",
      "snippets",
      "buffer",
      "omni",
    },

    -- Add LazyDev to the default sources for Lua files only.
    per_filetype = {
      lua = {
        inherit_defaults = true,
        "lazydev",
      },
    },

    providers = {
      -- Integrate LazyDev's Neovim and Lua library completions.
      lazydev = {
        name = "LazyDev",
        module = "lazydev.integrations.blink",
        score_offset = 100,
      },
    },
  },

  -- Use Neovim's native snippet engine for expansion and navigation.
  snippets = {
    preset = "default",
  },

  -- Configure command-line completion independently of Insert mode.
  cmdline = {
    enabled = true,

    -- Reuse the main Blink keymap.
    keymap = {
      preset = "inherit",
    },

    -- Provide completion from the current buffer and command-line context.
    sources = {
      "buffer",
      "cmdline",
    },

    completion = {
      menu = {
        -- Automatically display command-line completion suggestions.
        auto_show = true,
      },
    },
  },

  -- Prefer the Rust fuzzy matcher when available.
  -- Fall back with a warning when the Rust implementation is unavailable.
  fuzzy = {
    implementation = "prefer_rust_with_warning",
  },
})

