-- PowerShell formatting through PSScriptAnalyzer.
--
-- Uses PowerShell 7 and the PSScriptAnalyzer Invoke-Formatter command.
-- Reads the buffer from stdin and returns formatted PowerShell to stdout.

return {
  command = "pwsh",

  args = {
    "-NoLogo",
    "-NoProfile",
    "-NonInteractive",
    "-Command",
    [[
      $ErrorActionPreference = "Stop"

      try {
        Import-Module PSScriptAnalyzer -ErrorAction Stop

        $source = [Console]::In.ReadToEnd()

        $result = Invoke-Formatter -ScriptDefinition $source -ErrorAction Stop

        [Console]::Out.Write($result)
      }
      catch {
        [Console]::Error.WriteLine($_.ToString())
        exit 1
      }
    ]],
  },

  stdin = true,
}
