$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Source = Join-Path $ScriptDir "windows\coderun.ps1"

$InstallDir = Join-Path $env:USERPROFILE "bin"
$Target = Join-Path $InstallDir "coderun.ps1"
$Launcher = Join-Path $InstallDir "coderun.cmd"

Write-Host "Installing coderun for Windows..."
Write-Host ""

if (-not (Get-Command g++ -ErrorAction SilentlyContinue)) {
    Write-Host "Error: g++ was not found."
    Write-Host "Install GCC through MinGW-w64 or MSYS2 and add it to PATH."
    exit 1
}

if (-not (Get-Command gcc -ErrorAction SilentlyContinue)) {
    Write-Host "Error: gcc was not found."
    Write-Host "Install GCC through MinGW-w64 or MSYS2 and add it to PATH."
    exit 1
}

if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Host "Error: Python was not found."
    exit 1
}

New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null

Copy-Item $Source $Target -Force

@"
@echo off
powershell -ExecutionPolicy Bypass -File "%USERPROFILE%\bin\coderun.ps1" %*
"@ | Set-Content $Launcher

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

$env:Path = "$InstallDir;$env:Path"

Write-Host ""
Write-Host "coderun installed successfully!"
Write-Host "Location: $InstallDir"
Write-Host ""
Write-Host "Try:"
Write-Host "  coderun main.cpp"
Write-Host "  coderun main.c"
Write-Host "  coderun main.py"
Write-Host ""

