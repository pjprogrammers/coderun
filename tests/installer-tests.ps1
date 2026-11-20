$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot
$Installer = Join-Path $Root "install.ps1"
$TempRoot = Join-Path ([System.IO.Path]::GetTempPath()) "coderun-installer-tests-$PID"
$PathSeparator = [System.IO.Path]::PathSeparator
$IsWindowsHost = ($env:OS -eq "Windows_NT")
$OriginalPath = $env:PATH
$OriginalUserProfile = $env:USERPROFILE
$OriginalSkipPath = $env:CODERUN_INSTALL_SKIP_PATH
$Chmod = $null
$Pass = 0
$Fail = 0

if (-not $IsWindowsHost) {
    $Chmod = (Get-Command chmod -ErrorAction Stop).Source
}

if ($PSVersionTable.PSEdition -eq "Core") {
    $HostExe = Join-Path $PSHOME "pwsh"

    if (Test-Path -LiteralPath "$HostExe.exe") {
        $HostExe = "$HostExe.exe"
    }
}
else {
    $HostExe = Join-Path $PSHOME "powershell.exe"
}

function Write-Pass {
    param([string]$Name)

    Write-Host "PASS: $Name"
    $script:Pass++
}

function Write-Fail {
    param(
        [string]$Name,
        [string]$Detail = ""
    )

    Write-Host "FAIL: $Name"

    if ($Detail) {
        Write-Host $Detail
    }

    $script:Fail++
}

function Assert-Equal {
    param(
        [string]$Name,
        [string]$Expected,
        [string]$Actual
    )

    if ($Expected -eq $Actual) {
        Write-Pass $Name
    }
    else {
        Write-Fail $Name "expected: <$Expected>`nactual:   <$Actual>"
    }
}

function Assert-Contains {
    param(
        [string]$Name,
        [string]$Needle,
        [string]$Haystack
    )

    if ($Haystack.Contains($Needle)) {
        Write-Pass $Name
    }
    else {
        Write-Fail $Name "missing: <$Needle>`noutput:`n$Haystack"
    }
}

function Assert-NotContains {
    param(
        [string]$Name,
        [string]$Needle,
        [string]$Haystack
    )

    if ($Haystack.Contains($Needle)) {
        Write-Fail $Name "unexpected: <$Needle>`noutput:`n$Haystack"
    }
    else {
        Write-Pass $Name
    }
}

function New-FakeTools {
    param(
        [string]$Directory,
        [string[]]$Names
    )

    New-Item -ItemType Directory -Force -Path $Directory | Out-Null

    foreach ($name in $Names) {
        if ($IsWindowsHost) {
            Set-Content -LiteralPath (Join-Path $Directory "$name.cmd") -Value "@echo off`r`nexit /b 0`r`n" -Encoding ASCII
        }
        else {
            $path = Join-Path $Directory $name
            [System.IO.File]::WriteAllText($path, "#!/bin/bash`nexit 0`n")
            & $Chmod 755 $path
        }
    }
}

function Invoke-Installer {
    param(
        [string]$UserHome,
        [string]$ToolsDirectory = ""
    )

    $env:USERPROFILE = $UserHome
    $env:CODERUN_INSTALL_SKIP_PATH = "1"

    if ([string]::IsNullOrWhiteSpace($ToolsDirectory)) {
        $env:PATH = Join-Path $TempRoot "empty-bin"
    }
    else {
        $env:PATH = "$ToolsDirectory$PathSeparator$(Join-Path $TempRoot 'empty-bin')"
    }

    $lines = & $HostExe -NoProfile -ExecutionPolicy Bypass -File $Installer 2>&1
    $code = $LASTEXITCODE
    $text = ($lines | Out-String)

    return [pscustomobject]@{
        Output = $text
        Code = $code
    }
}

New-Item -ItemType Directory -Force -Path $TempRoot | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $TempRoot "empty-bin") | Out-Null

try {
    # -----------------------------------------------------------------------
    # Missing tools
    # -----------------------------------------------------------------------

    $homeDir = Join-Path $TempRoot "home"
    $result = Invoke-Installer $homeDir

    Assert-Equal "Windows install succeeds without gcc/g++/python" "0" "$($result.Code)"
    Assert-Contains "Windows install warns about g++" "warning: g++ was not found." $result.Output
    Assert-Contains "Windows install warns about gcc" "warning: gcc was not found." $result.Output
    Assert-Contains "Windows install warns about python" "warning: python was not found." $result.Output
    Assert-Contains "Windows install confirms success" "coderun installed successfully!" $result.Output
    Assert-NotContains "Windows install does not report an error" "Error:" $result.Output

    $target = Join-Path (Join-Path $homeDir "bin") "coderun.ps1"
    $launcher = Join-Path (Join-Path $homeDir "bin") "coderun.cmd"

    if (Test-Path -LiteralPath $target -PathType Leaf) {
        Write-Pass "Windows installer copies coderun.ps1"
    }
    else {
        Write-Fail "Windows installer copies coderun.ps1"
    }

    if (Test-Path -LiteralPath $launcher -PathType Leaf) {
        Write-Pass "Windows installer creates coderun.cmd"
    }
    else {
        Write-Fail "Windows installer creates coderun.cmd"
    }

    $sourceHash = (Get-FileHash -LiteralPath (Join-Path $Root "windows\coderun.ps1") -Algorithm SHA256).Hash
    $targetHash = (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash
    Assert-Equal "Windows installed runner matches windows/coderun.ps1" $sourceHash $targetHash
    Assert-Contains "Windows launcher invokes coderun.ps1" "coderun.ps1" (Get-Content -LiteralPath $launcher -Raw)

    $result = Invoke-Installer $homeDir
    Assert-Equal "Windows reinstall succeeds" "0" "$($result.Code)"
    Assert-Contains "Windows reinstall reports upgrade" "Existing installation found - upgrading..." $result.Output

    # -----------------------------------------------------------------------
    # Tools present and paths with spaces
    # -----------------------------------------------------------------------

    $tools = Join-Path $TempRoot "tools"
    New-FakeTools $tools @("gcc", "g++", "python")
    $spacedHome = Join-Path $TempRoot "home with spaces"
    $result = Invoke-Installer $spacedHome $tools

    Assert-Equal "Windows install succeeds with tools and a spaced HOME" "0" "$($result.Code)"
    Assert-NotContains "Windows install has no warnings when tools exist" "warning:" $result.Output
    Assert-Contains "Spaced HOME install confirms success" "coderun installed successfully!" $result.Output

    if (Test-Path -LiteralPath (Join-Path (Join-Path $spacedHome "bin") "coderun.ps1") -PathType Leaf) {
        Write-Pass "Spaced HOME contains installed runner"
    }
    else {
        Write-Fail "Spaced HOME contains installed runner"
    }
}
finally {
    $env:PATH = $OriginalPath
    $env:USERPROFILE = $OriginalUserProfile

    if ([string]::IsNullOrEmpty($OriginalSkipPath)) {
        Remove-Item Env:CODERUN_INSTALL_SKIP_PATH -ErrorAction SilentlyContinue
    }
    else {
        $env:CODERUN_INSTALL_SKIP_PATH = $OriginalSkipPath
    }

    Remove-Item -LiteralPath $TempRoot -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host ""
Write-Host "Passed: $Pass  Failed: $Fail"

if ($Fail -ne 0) {
    exit 1
}
