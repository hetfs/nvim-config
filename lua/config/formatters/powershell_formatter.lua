return {
  command = "pwsh",

  args = {
    "-NoLogo",
    "-NoProfile",
    "-NonInteractive",
    "-Command",
    [[
      Import-Module PSScriptAnalyzer -ErrorAction Stop

      $source = [Console]::In.ReadToEnd()
      $source = $source -replace "`r`n|`r|`n", "`r`n"

      $result = Invoke-Formatter -ScriptDefinition $source

      [Console]::Out.Write($result)
    ]],
  },

  stdin = true,
}
