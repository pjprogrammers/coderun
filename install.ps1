$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Source = Join-Path $ScriptDir "windows\coderun.ps1"

$InstallDir = Join-Path $env:USERPROFILE "bin"
$Target = Join-Path $InstallDir "coderun.ps1"
$Launcher = Join-Path $InstallDir "coderun.cmd"

if (!(Test-Path -LiteralPath $Source -PathType Leaf)) {
    Write-Host "Error: runner not found at $Source."
    exit 1
}

if (Test-Path -LiteralPath $Target -PathType Leaf) {
    Write-Host "Existing installation found - upgrading..."
} else {
    Write-Host "Installing coderun for Windows..."
}
Write-Host ""

$Warned = $false
$Checks = @(
    @{ Tool = "g++"; Hint = "Install GCC through MinGW-w64 or MSYS2 and add it to PATH." },
    @{ Tool = "gcc"; Hint = "Install GCC through MinGW-w64 or MSYS2 and add it to PATH." },
    @{ Tool = "python"; Hint = "Install Python from https://www.python.org/downloads/." }
)

foreach ($check in $Checks) {
    if (-not (Get-Command $check.Tool -ErrorAction SilentlyContinue)) {
        if (-not $Warned) {
            Write-Host "Note: coderun does not require these tools to install,"
            Write-Host "but languages that use them will not run until they are available."
            $Warned = $true
        }

        Write-Host "  warning: $($check.Tool) was not found. $($check.Hint)"
    }
}

if ($Warned) {
    Write-Host ""
    Write-Host "Run 'coderun --check' after installation to see which toolchains are ready."
}

New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null

Copy-Item $Source $Target -Force

@"
@echo off
powershell -ExecutionPolicy Bypass -File "%USERPROFILE%\bin\coderun.ps1" %*
"@ | Set-Content -Path $Launcher -Encoding ASCII

if (-not $env:CODERUN_INSTALL_SKIP_PATH) {
    $UserPath = [Environment]::GetEnvironmentVariable("Path", "User")

    if (-not $UserPath) {
        $UserPath = ""
    }

    $PathEntries = $UserPath -split ";" | Where-Object { $_ -ne "" }

    if ($PathEntries -notcontains $InstallDir) {

        if ($UserPath -and -not $UserPath.EndsWith(";")) {
            $UserPath += ";"
        }

        $UserPath += $InstallDir

        [Environment]::SetEnvironmentVariable(
            "Path",
            $UserPath,
            "User"
        )
    }
}

$env:Path = "$InstallDir;$env:Path"

Write-Host ""
Write-Host "coderun installed successfully!"
Write-Host "Location: $InstallDir"
Write-Host ""
Write-Host "Try:"
Write-Host "  coderun main.cpp"
Write-Host "  coderun main.py --verbose"
Write-Host "  coderun --check"
Write-Host ""
