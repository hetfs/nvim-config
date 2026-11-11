
-- On-demand Markdown table-of-contents generation.
--
-- Uses the current buffer, including unsaved changes.
-- Runs markdown-toc against a temporary file.
-- Updates the buffer only after successful execution.
-- No automatic generation or dependency installation.

local M = {}

local requests = {}
local next_request_id = 0
local configured = false

local OPEN_MARKER = "<!-- toc -->"
local CLOSE_MARKER = "<!-- tocstop -->"

local function notify(message, level)
  vim.notify(message, level, {
    title = "MarkdownToc",
  })
end

local function resolve_command()
  local node = vim.fn.exepath("node")
  local cli = vim.fn.exepath("markdown-toc")

  if node == "" then
    return nil, "Node.js was not found in Neovim's PATH."
  end

  if cli == "" then
    return nil, "markdown-toc was not found in Neovim's PATH."
  end

  local global_bin = vim.fs.dirname(cli)

  -- Support the original package and the maintained fork.
  local packages = {
    vim.fs.joinpath(global_bin, "node_modules", "@frat", "markdown-toc"),
    vim.fs.joinpath(global_bin, "node_modules", "markdown-toc"),
  }

  for _, package_root in ipairs(packages) do
    local manifest = vim.fs.joinpath(package_root, "package.json")

    if vim.fn.filereadable(manifest) == 1 then
      local content = table.concat(vim.fn.readfile(manifest), "\n")
      local ok, package = pcall(vim.json.decode, content)

      if ok and type(package) == "table" then
        local bin = package.bin
        local entrypoint

        if type(bin) == "string" then
          entrypoint = bin
        elseif type(bin) == "table" then
          entrypoint = bin["markdown-toc"]
        end

        if type(entrypoint) == "string" and entrypoint ~= "" then
          entrypoint = vim.fs.joinpath(package_root, entrypoint)

          if vim.fn.filereadable(entrypoint) == 1 then
            return {
              node,
              entrypoint,
            }
          end
        end
      end
    end
  end

  return nil, "Could not locate the markdown-toc Node entry point."
end

local function validate_markers(lines)
  local open_index
  local close_index

  for index, line in ipairs(lines) do
    local trimmed = vim.trim(line)

    if trimmed == OPEN_MARKER then
      if open_index then
        return false, "Multiple TOC opening markers were found."
      end

      open_index = index
    elseif trimmed == CLOSE_MARKER then
      if close_index then
        return false, "Multiple TOC closing markers were found."
      end

      close_index = index
    end
  end

  if not open_index or not close_index then
    return false, "Add both " .. OPEN_MARKER .. " and " .. CLOSE_MARKER .. "."
  end

  if open_index >= close_index then
    return false, "The TOC opening marker must precede the closing marker."
  end

  return true
end

local function cleanup(path)
  if path then
    pcall(vim.uv.fs_unlink, path)
  end
end

local function finish_request(bufnr, request_id)
  if requests[bufnr] == request_id then
    requests[bufnr] = nil
  end
end

local function process_result(bufnr, request_id, changedtick, endofline, temp_path, result)
  -- Read the generated content before removing the temporary file.
  local output
  local read_error

  if result.code == 0 then
    local ok, lines = pcall(vim.fn.readfile, temp_path)

    if ok then
      output = lines
    else
      read_error = tostring(lines)
    end
  end

  cleanup(temp_path)

  -- Ignore results belonging to an invalid or superseded buffer request.
  if not vim.api.nvim_buf_is_valid(bufnr)
    or not vim.api.nvim_buf_is_loaded(bufnr)
  then
    finish_request(bufnr, request_id)
    return
  end

  if requests[bufnr] ~= request_id then
    return
  end

  finish_request(bufnr, request_id)

  if vim.api.nvim_buf_get_changedtick(bufnr) ~= changedtick then
    notify(
      "Buffer changed during TOC generation. Run :MarkdownToc again.",
      vim.log.levels.WARN
    )
    return
  end

  if result.code ~= 0 then
    local message = vim.trim(result.stderr or "")

    if message == "" then
      message = vim.trim(result.stdout or "")
    end

    if message == "" then
      message = "Process exited with code " .. tostring(result.code) .. "."
    end

    notify("markdown-toc failed:\n" .. message, vim.log.levels.ERROR)
    return
  end

  if not output then
    notify(
      "Could not read the generated TOC: " .. (read_error or "unknown error"),
      vim.log.levels.ERROR
    )
    return
  end

  if not vim.bo[bufnr].modifiable then
    notify("The buffer is no longer modifiable.", vim.log.levels.WARN)
    return
  end

  local current = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  if vim.deep_equal(current, output) then
    notify("Table of contents is already up to date.", vim.log.levels.INFO)
    return
  end

  local ok, update_error = pcall(
    vim.api.nvim_buf_set_lines,
    bufnr,
    0,
    -1,
    false,
    output
  )

  if not ok then
    notify(
      "Could not update the Markdown buffer: " .. tostring(update_error),
      vim.log.levels.ERROR
    )
    return
  end

  -- Keep the original end-of-line setting.
  vim.bo[bufnr].endofline = endofline

  notify("Table of contents updated.", vim.log.levels.INFO)
end

function M.generate(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  if not vim.api.nvim_buf_is_valid(bufnr)
    or not vim.api.nvim_buf_is_loaded(bufnr)
  then
    notify("The current buffer is not available.", vim.log.levels.WARN)
    return
  end

  if vim.bo[bufnr].filetype ~= "markdown" then
    notify("The current buffer is not Markdown.", vim.log.levels.WARN)
    return
  end

  if not vim.bo[bufnr].modifiable then
    notify("The current buffer is not modifiable.", vim.log.levels.WARN)
    return
  end

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local valid, marker_error = validate_markers(lines)

  if not valid then
    notify(marker_error, vim.log.levels.WARN)
    return
  end

  local command, command_error = resolve_command()

  if not command then
    notify(command_error, vim.log.levels.ERROR)
    return
  end

  local temp_path = vim.fn.tempname() .. ".md"

  if vim.fn.writefile(lines, temp_path) ~= 0 then
    cleanup(temp_path)
    notify("Could not write the temporary Markdown file.", vim.log.levels.ERROR)
    return
  end

  command[#command + 1] = "-i"
  command[#command + 1] = temp_path

  next_request_id = next_request_id + 1

  local request_id = next_request_id
  local changedtick = vim.api.nvim_buf_get_changedtick(bufnr)
  local endofline = vim.bo[bufnr].endofline

  requests[bufnr] = request_id

  local ok, process = pcall(vim.system, command, {
    text = true,
  }, function(result)
    vim.schedule(function()
      process_result(
        bufnr,
        request_id,
        changedtick,
        endofline,
        temp_path,
        result
      )
    end)
  end)

  if not ok then
    finish_request(bufnr, request_id)
    cleanup(temp_path)

    notify(
      "Could not start markdown-toc: " .. tostring(process),
      vim.log.levels.ERROR
    )

    return
  end

  return process
end

function M.setup()
  if configured then
    return
  end

  local group = vim.api.nvim_create_augroup("MarkdownToc", {
    clear = true,
  })

  vim.api.nvim_create_autocmd("BufWipeout", {
    group = group,
    desc = "Clean up Markdown TOC requests",
    callback = function(event)
      requests[event.buf] = nil
    end,
  })

  vim.api.nvim_create_user_command("MarkdownToc", function()
    M.generate()
  end, {
    desc = "Generate or update the Markdown table of contents",
    force = true,
  })

  configured = true
end

return M

