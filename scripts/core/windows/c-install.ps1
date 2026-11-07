
Both C integration tests passed

Good. We now have successful validation against the repository under development.

## Validation results

| Test                                  | Result |
| ------------------------------------- | ------ |
| C pack discovery                      | Pass   |
| C parser metadata (`c`)               | Pass   |
| C formatter metadata (`clang_format`) | Pass   |
| Shared clangd configuration           | Pass   |
| clangd activation                     | Pass   |
| Repeated setup calls                  | Pass   |
| C-only filetype selection             | Pass   |

The shared clangd test confirms that:

- `clangd` is configured once.
- `clangd` is enabled once.
- Its configured filetypes contain only `c`.
- Calling `setup()` again does not repeat activation.

The initial source-path diagnostic returned `nil` because `package.searchpath()` examines Lua's `package.path`, not Neovim's `runtimepath`. That output does not indicate a loading failure. The subsequent successful `require()`-based tests are the relevant evidence.

## C implementation status

Configuration-level validation complete

The following parts are now validated:

1. C language-pack discovery and metadata.
2. Formatter and parser registration.
3. Shared clangd activation logic.
4. Separation between C and future C++ activation.

The following remain unvalidated:

- Actual clangd executable and LSP attachment.
- `clang-format` integration through Conform.
- C Treesitter parser installation and highlighting.
- C compilation using GCC.
- `clang-tidy` analysis.

## Next step: LLVM tooling

Before testing real LSP and formatting behavior, we need to make these three executables available:

| Executable     | Purpose         |
| -------------- | --------------- |
| `clangd`       | Language server |
| `clang-format` | Formatter       |
| `clang-tidy`   | Static analysis |

Installing the official LLVM Windows toolchain and keeping your existing WinLibs GCC/G++ installation unchanged. This preserves the distinction between the compiler and the LLVM editor tooling.

$installer = Join-Path $env:TEMP "LLVM-23.1.5-win64.msi"

$downloadUrl = "https://github.com/llvm/llvm-project/releases/download/llvmorg-23.1.5/LLVM-23.1.5-win64.msi"

Invoke-WebRequest -Uri $downloadUrl -OutFile $installer

Get-Item $installer | Select-Object FullName, Length

Start-Process msiexec.exe -ArgumentList @(
    "/i",
    "`"$installer`""
) -Wait

proceed with LLVM installation and Windows PATH validation now

$llvmBin = Join-Path $env:ProgramFiles "LLVM\bin"

if (-not (Test-Path $llvmBin)) {
    throw "LLVM installation directory not found: $llvmBin"
}

$userPath = [Environment]::GetEnvironmentVariable("Path", "User")

$pathEntries = @(
    $userPath -split ";" |
        ForEach-Object { $_.Trim().TrimEnd("\") } |
        Where-Object { $_ }
)

if ($pathEntries -notcontains $llvmBin.TrimEnd("\")) {
    $newUserPath = (@($pathEntries) + $llvmBin) -join ";"
    [Environment]::SetEnvironmentVariable("Path", $newUserPath, "User")
}

# Update this PowerShell session too.
if (($env:Path -split ";") -notcontains $llvmBin) {
    $env:Path = "$llvmBin;$env:Path"
}

Write-Host "LLVM PATH: $llvmBin" -ForegroundColor Green


Validate the required executables

$tools = @(
    "clangd",
    "clang-format",
    "clang-tidy",
    "clang"
)

foreach ($tool in $tools) {
    Write-Host "`n--- $tool ---" -ForegroundColor Cyan

    $command = Get-Command $tool -ErrorAction SilentlyContinue

    if ($command) {
        Write-Host "Path: $($command.Source)" -ForegroundColor Green
        & $tool --version | Select-Object -First 2
    }
    else {
        Write-Host "Not available on PATH" -ForegroundColor Red
    }
}



Also confirm that GCC remains available:

Get-Command gcc, g++ |
    Select-Object Name, Source

gcc --version | Select-Object -First 2
g++ --version | Select-Object -First 2

