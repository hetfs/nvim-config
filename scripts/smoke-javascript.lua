
-- Stage 13: JavaScript, JSX, TypeScript, and TSX smoke tests.
--
-- Usage:
--   nvim --headless -u init.lua -l scripts/smoke-javascript.lua

local function check(condition, message)
  if not condition then
    error("FAIL nvim-config: " .. message, 2)
  end
end

local function check_equal(actual, expected, message)
  check(
    vim.deep_equal(actual, expected),
    string.format(
      "%s (expected %s, got %s)",
      message,
      vim.inspect(expected),
      vim.inspect(actual)
    )
  )
end

local function check_formatter(formatters, filetype, expected)
  check_equal(
    formatters[filetype],
    expected,
    string.format("%s formatter configuration", filetype)
  )
end

local function check_parser(parsers, filetype, expected)
  check_equal(
    parsers[filetype],
    expected,
    string.format("%s Tree-sitter parser configuration", filetype)
  )
end

local function main()
  local langs = require("langs")
  local language_config = require("config.languages")

  -- Verify language-pack activation.
  check(
    language_config.packs.javascript == true,
    "JavaScript language pack is enabled"
  )

  check(
    language_config.packs.typescript == true,
    "TypeScript language pack is enabled"
  )

  check(langs.is_enabled("javascript"), "JavaScript pack is active")
  check(langs.is_enabled("typescript"), "TypeScript pack is active")

  -- Collect metadata through the production language registry.
  local formatters = langs.collect("formatters")
  local parsers = langs.collect("parser_by_filetype")

  -- JavaScript.
  check_formatter(formatters, "javascript", { "prettier" })
  check_parser(parsers, "javascript", "javascript")

  -- JSX.
  check_formatter(formatters, "javascriptreact", { "prettier" })
  check_parser(parsers, "javascriptreact", "javascript")

  -- TypeScript.
  check_formatter(formatters, "typescript", { "prettier" })
  check_parser(parsers, "typescript", "typescript")

  -- TSX.
  check_formatter(formatters, "typescriptreact", { "prettier" })
  check_parser(parsers, "typescriptreact", "tsx")

  print("PASS Stage 13 JavaScript, JSX, TypeScript, and TSX")
end

main()
