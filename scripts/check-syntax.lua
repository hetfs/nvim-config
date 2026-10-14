-- Usage: nvim -l scripts/check-syntax.lua

local uv = vim.uv

local function collect(directory, files)
  local stat, stat_err, err_name = uv.fs_stat(directory)

  if not stat then
    if err_name ~= "ENOENT" then
      error(string.format("Unable to inspect '%s': %s", directory, stat_err), 0)
    end

    return
  end

  if stat.type ~= "directory" then
    error(string.format("Expected '%s' to be a directory", directory), 0)
  end

  for name, kind in vim.fs.dir(directory) do
    local path = directory .. "/" .. name

    if kind == "directory" then
      collect(path, files)
    elseif kind == "file" and name:match("%.lua$") then
      files[#files + 1] = path
    end
  end
end

local files = { "init.lua" }

collect("lua", files)
collect("scripts", files)

table.sort(files)

local failures = 0

for _, path in ipairs(files) do
  local chunk, err = loadfile(path)

  if chunk then
    print("PASS " .. path)
  else
    failures = failures + 1
    io.stderr:write(string.format("FAIL %s: %s\n", path, err))
  end
end

if failures > 0 then
  io.stderr:write(string.format("\nSyntax check failed: %d of %d files.\n", failures, #files))

  os.exit(1)
end

print(string.format("\nSyntax check passed: %d Lua files.", #files))
