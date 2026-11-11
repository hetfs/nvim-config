[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:Results = [System.Collections.Generic.List[object]]::new()

function Add-CheckResult {
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$Status,

        [Parameter(Mandatory)]
        [string]$Message
    )

    $script:Results.Add([PSCustomObject]@{
        Name    = $Name
        Status  = $Status
        Message = $Message
    })
}

function Test-ExternalCommand {
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string[]]$Arguments
    )

    $command = Get-Command -Name $Name -CommandType Application `
        -ErrorAction SilentlyContinue |
        Select-Object -First 1

    if (-not $command) {
        Add-CheckResult -Name $Name -Status 'FAIL' `
            -Message 'Executable not found in PATH.'
        return
    }

    try {
        $output = @(& $command.Source @Arguments 2>&1)
        $exitCode = $LASTEXITCODE

        $message = ($output |
            ForEach-Object { "$_".Trim() } |
            Where-Object { $_ }) -join ' '

        if ($exitCode -ne 0) {
            Add-CheckResult -Name $Name -Status 'FAIL' `
                -Message "Command exited with code $exitCode. $message"
            return
        }

        if (-not $message) {
            $message = 'Command executed successfully.'
        }

        Add-CheckResult -Name $Name -Status 'OK' -Message $message
    }
    catch {
        Add-CheckResult -Name $Name -Status 'FAIL' `
            -Message $_.Exception.Message
    }
}

Write-Host ''
Write-Host 'External dependency checks' -ForegroundColor Cyan
Write-Host ''

$checks = @(
    @{ Name = 'tectonic'; Arguments = @('--version') }
    @{ Name = 'mmdc';     Arguments = @('--version') }
    @{ Name = 'magick';   Arguments = @('-version') }
    @{ Name = 'gs';       Arguments = @('--version') }
)

foreach ($check in $checks) {
    Test-ExternalCommand `
        -Name $check.Name `
        -Arguments $check.Arguments
}

Write-Host 'Results' -ForegroundColor Cyan
Write-Host ''

foreach ($result in $script:Results) {
    $color = if ($result.Status -eq 'OK') {
        'Green'
    }
    else {
        'Red'
    }

    Write-Host (
        '[{0}] {1,-12} {2}' -f
        $result.Status,
        $result.Name,
        $result.Message
    ) -ForegroundColor $color
}

$passed = @($script:Results | Where-Object Status -eq 'OK').Count
$failed = @($script:Results | Where-Object Status -eq 'FAIL').Count

Write-Host ''
Write-Host 'Summary' -ForegroundColor Cyan
Write-Host "Checked: $($script:Results.Count)"
Write-Host "Passed:  $passed" -ForegroundColor Green
Write-Host "Failed:  $failed" -ForegroundColor $(if ($failed) { 'Red' } else { 'Green' })
Write-Host ''

if ($failed -gt 0) {
    exit 1
}

exit 0
