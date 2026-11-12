-- Stage 13: Mermaid code-block rendering.
--
-- Extracts the fenced Mermaid block containing the cursor,
-- renders it with the installed Mermaid CLI, and opens the
-- resulting SVG using the operating system's default application.
--
-- The Markdown buffer is never modified.
-- No package installation or npx fallback is performed.

local M = {}

local RENDER_TIMEOUT_MS = 30000
local SHUTDOWN_WAIT_MS = 1000

local configured = false
local temporary_files = {}
local active_temp_path
local active_output_path
local active_process
local latest_request_id = 0

local function notify(message, level)
  vim.notify(message, level, { title = "MermaidRender" })
end

-- Resolve external dependencies.

local function get_mmdc()
  local executable = vim.fn.exepath("mmdc")

  if executable == "" then
    return nil, "Mermaid CLI (mmdc) was not found in Neovim's PATH."
  end

  return executable
end

local function chrome_candidates()
  local candidates = {}

  local function add(path)
    if path and path ~= "" then
      candidates[#candidates + 1] = path
    end
  end

  if vim.fn.has("win32") == 1 then
    local roots = {
      vim.env.PROGRAMFILES,
      vim.env["ProgramFiles(x86)"],
      vim.env.LOCALAPPDATA,
    }

    for _, root in ipairs(roots) do
      if root and root ~= "" then
        add(vim.fs.joinpath(root, "Google", "Chrome", "Application", "chrome.exe"))
      end
    end

    add(vim.fn.exepath("chrome"))
    add(vim.fn.exepath("chromium"))
  elseif vim.fn.has("mac") == 1 then
    local browsers = {
      {
        "Applications",
        "Google Chrome.app",
        "Contents",
        "MacOS",
        "Google Chrome",
      },
      {
        "Applications",
        "Chromium.app",
        "Contents",
        "MacOS",
        "Chromium",
      },
    }

    for _, parts in ipairs(browsers) do
      add(vim.fs.joinpath("/", unpack(parts)))

      if vim.env.HOME and vim.env.HOME ~= "" then
        add(vim.fs.joinpath(vim.env.HOME, unpack(parts)))
      end
    end
  else
    local names = {
      "google-chrome",
      "google-chrome-stable",
      "chromium",
      "chromium-browser",
      "chrome",
    }

    for _, name in ipairs(names) do
      add(vim.fn.exepath(name))
    end
  end

  return candidates
end

local function get_chrome()
  local override = vim.env.CHROME_PATH or vim.env.CHROMIUM_PATH

  if override and override ~= "" then
    if vim.fn.filereadable(override) == 1 then
      return override
    end

    return nil, "CHROME_PATH or CHROMIUM_PATH does not point to a readable browser executable."
  end

  for _, path in ipairs(chrome_candidates()) do
    if vim.fn.filereadable(path) == 1 then
      return path
    end
  end

  return nil, "Chrome/Chromium was not found. Set CHROME_PATH or CHROMIUM_PATH to the browser executable."
end

-- Parse CommonMark fenced code blocks.

local function parse_opening_fence(line)
  local indent, fence, info = line:match("^( *)([`~]+)(.*)$")

  if not indent or #indent > 3 or #fence < 3 then
    return nil
  end

  local marker = fence:sub(1, 1)

  if not fence:match("^" .. marker .. "+$") then
    return nil
  end

  if marker == "`" and info:find("`", 1, true) then
    return nil
  end

  return {
    marker = marker,
    length = #fence,
    info = info,
  }
end

local function is_closing_fence(line, opening)
  local indent, fence = line:match("^( *)([`~]+)%s*$")

  if not indent or #indent > 3 or #fence < opening.length then
    return false
  end

  if fence:sub(1, 1) ~= opening.marker then
    return false
  end

  return fence:match("^" .. opening.marker .. "+$") ~= nil
end

local function is_mermaid(info)
  local language = vim.trim(info):match("^([%w_+.-]+)")

  return language ~= nil and language:lower() == "mermaid"
end

local function find_mermaid_block(lines, cursor_line)
  local index = 1

  while index <= #lines do
    local opening = parse_opening_fence(lines[index])

    if not opening then
      index = index + 1
    else
      local closing_index

      for candidate = index + 1, #lines do
        if is_closing_fence(lines[candidate], opening) then
          closing_index = candidate
          break
        end
      end

      local block_end = closing_index or #lines

      if cursor_line >= index and cursor_line <= block_end then
        if not is_mermaid(opening.info) then
          return nil, "The fenced code block under the cursor is not Mermaid."
        end

        if not closing_index then
          return nil, "The Mermaid code block has no closing fence."
        end

        local content = {}

        for line = index + 1, closing_index - 1 do
          content[#content + 1] = lines[line]
        end

        return content
      end

      index = closing_index and closing_index + 1 or #lines + 1
    end
  end

  return nil, "Place the cursor inside a fenced Mermaid code block."
end

-- Manage temporary files.

local function cleanup(path)
  if not path then
    return
  end

  pcall(vim.fn.delete, path)

  temporary_files[path] = nil

  if active_temp_path == path then
    active_temp_path = nil
  end

  if active_output_path == path then
    active_output_path = nil
  end
end

local function cleanup_active()
  local input_path = active_temp_path
  local output_path = active_output_path

  active_temp_path = nil
  active_output_path = nil

  cleanup(input_path)
  cleanup(output_path)
end

local function cleanup_all()
  local paths = vim.tbl_keys(temporary_files)

  for _, path in ipairs(paths) do
    cleanup(path)
  end

  active_temp_path = nil
  active_output_path = nil
end

local function cancel_active_process(wait_timeout)
  local process = active_process

  active_process = nil

  if not process then
    return
  end

  pcall(process.kill, process, "sigterm")

  if wait_timeout then
    pcall(process.wait, process, wait_timeout)
  end
end

local function create_puppeteer_config(chrome)
  local config_path = vim.fn.tempname() .. ".json"
  local config = vim.json.encode({
    executablePath = chrome,
  })

  if vim.fn.writefile({ config }, config_path) ~= 0 then
    pcall(vim.fn.delete, config_path)

    return nil, "Could not write the temporary Puppeteer configuration."
  end

  temporary_files[config_path] = true

  return config_path
end

-- Render the extracted Mermaid source asynchronously.

local function failure_message(result)
  if result.code == 124 then
    return "mmdc timed out after " .. (RENDER_TIMEOUT_MS / 1000) .. " seconds."
  end

  local message = vim.trim(result.stderr or "")

  if message == "" then
    message = vim.trim(result.stdout or "")
  end

  if message == "" then
    message = "mmdc exited with code " .. tostring(result.code) .. "."
  end

  return message
end

local function open_output(output_path)
  -- vim.ui.open() reports failure through its return values.
  local ok, handle, err = pcall(vim.ui.open, output_path)

  if ok and handle then
    notify("Mermaid diagram rendered successfully.\nSVG: " .. output_path, vim.log.levels.INFO)

    return
  end

  notify(
    "Mermaid rendered successfully, but the SVG could not be opened:\n" .. tostring(ok and err or handle) .. "\nSVG: " .. output_path,
    vim.log.levels.ERROR
  )
end

local function render(mmdc, input_path, output_path, config_path, request_id)
  local command = {
    mmdc,
    "--puppeteerConfigFile",
    config_path,
    "--input",
    input_path,
    "--output",
    output_path,
  }

  local ok, process = pcall(vim.system, command, {
    text = true,
    timeout = RENDER_TIMEOUT_MS,
  }, function(result)
    vim.schedule(function()
      -- The Puppeteer configuration is no longer needed.
      cleanup(config_path)

      -- Ignore results from superseded requests.
      if request_id ~= latest_request_id then
        cleanup(input_path)
        cleanup(output_path)
        return
      end

      active_process = nil

      if result.code ~= 0 then
        cleanup(output_path)

        notify("Mermaid rendering failed:\n" .. failure_message(result) .. "\nSource retained at:\n" .. input_path, vim.log.levels.ERROR)

        return
      end

      if vim.fn.filereadable(output_path) ~= 1 then
        cleanup(output_path)

        notify("mmdc completed but the SVG output was not created.\n" .. "Source retained at:\n" .. input_path, vim.log.levels.ERROR)

        return
      end

      -- Replace the previous successful render only after
      -- the new SVG has been generated successfully.
      cleanup_active()

      active_temp_path = input_path
      active_output_path = output_path

      open_output(output_path)
    end)
  end)

  if not ok then
    cleanup(config_path)
    cleanup(input_path)
    cleanup(output_path)

    notify("Could not start Mermaid CLI:\n" .. tostring(process), vim.log.levels.ERROR)

    return
  end

  return process
end

-- Public rendering entry point.

function M.render()
  local bufnr = vim.api.nvim_get_current_buf()

  if not vim.api.nvim_buf_is_valid(bufnr) or not vim.api.nvim_buf_is_loaded(bufnr) then
    notify("The current buffer is not available.", vim.log.levels.WARN)
    return
  end

  if vim.bo[bufnr].filetype ~= "markdown" then
    notify("The current buffer is not Markdown.", vim.log.levels.WARN)
    return
  end

  local mmdc, mmdc_error = get_mmdc()

  if not mmdc then
    notify(mmdc_error, vim.log.levels.ERROR)
    return
  end

  local chrome, chrome_error = get_chrome()

  if not chrome then
    notify(chrome_error, vim.log.levels.ERROR)
    return
  end

  local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  local content, extraction_error = find_mermaid_block(lines, cursor_line)

  if not content then
    notify(extraction_error, vim.log.levels.WARN)
    return
  end

  local input_path = vim.fn.tempname() .. ".mmd"
  local output_path = vim.fn.tempname() .. ".svg"

  if vim.fn.writefile(content, input_path) ~= 0 then
    pcall(vim.fn.delete, input_path)

    notify("Could not write the temporary Mermaid file.", vim.log.levels.ERROR)
    return
  end

  temporary_files[input_path] = true
  temporary_files[output_path] = true

  local config_path, config_error = create_puppeteer_config(chrome)

  if not config_path then
    cleanup(input_path)
    cleanup(output_path)

    notify(config_error, vim.log.levels.ERROR)
    return
  end

  -- Supersede any render still in flight.
  latest_request_id = latest_request_id + 1
  cancel_active_process()

  notify("Rendering Mermaid diagram...", vim.log.levels.INFO)

  active_process = render(mmdc, input_path, output_path, config_path, latest_request_id)

  return active_process
end

-- Register the user command and lifecycle cleanup.

function M.setup()
  if configured then
    return
  end

  local group = vim.api.nvim_create_augroup("MarkdownMermaid", {
    clear = true,
  })

  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = group,
    desc = "Clean up temporary Mermaid files",
    callback = function()
      cancel_active_process(SHUTDOWN_WAIT_MS)
      cleanup_all()
    end,
  })

  vim.api.nvim_create_user_command("MermaidRender", function()
    M.render()
  end, {
    desc = "Render the Mermaid code block under the cursor",
    force = true,
  })

  configured = true
end

return M
