-- Compile Lua files without executing them.
-- Usage: nvim --headless -l scripts/check-syntax.lua

local files = {}

local function collect_lua_files(directory)
  local entries = vim.fn.globpath(directory, "**/*.lua", false, true)

  for _, file in ipairs(entries) do
    files[#files + 1] = file
  end
end

-- Check the entry point separately.
if vim.fn.filereadable("init.lua") == 1 then
  files[#files + 1] = "init.lua"
end

collect_lua_files("lua")
collect_lua_files("scripts")

table.sort(files)

local failures = {}

for _, file in ipairs(files) do
  local source = table.concat(vim.fn.readfile(file), "\n")
  local chunk, err = loadstring(source, "@" .. file)

  if chunk then
    print("PASS " .. file)
  else
    failures[#failures + 1] = {
      file = file,
      error = err,
    }

    io.stderr:write(string.format("FAIL %s\n  %s\n", file, tostring(err)))
  end
end

if #failures > 0 then
  io.stderr:write(string.format("\nSyntax check failed: %d of %d Lua files contain errors.\n", #failures, #files))

  vim.cmd.cquit(1)
end

print(string.format("\nSyntax check passed: %d Lua files.", #files))
