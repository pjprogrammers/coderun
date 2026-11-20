$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot
$Runner = Join-Path $Root "windows\coderun.ps1"
$Version = (Get-Content -LiteralPath (Join-Path $Root "VERSION") -Raw).Trim()
$TempRoot = Join-Path ([System.IO.Path]::GetTempPath()) "coderun-pwsh-tests-$PID"
$FakeBin = Join-Path $TempRoot "fake-bin"
$Work = Join-Path $TempRoot "work"
$ShimLog = Join-Path $TempRoot "shims.log"
$Pass = 0
$Fail = 0
$Server = $null
$OriginalPath = $env:PATH
$OriginalUserProfile = $env:USERPROFILE
$OriginalRawBase = $env:CODERUN_RAW_BASE
$PathSeparator = [System.IO.Path]::PathSeparator
$IsWindowsHost = ($env:OS -eq "Windows_NT")
$RealPython = Get-Command python -ErrorAction SilentlyContinue

if ($null -eq $RealPython) {
    $RealPython = Get-Command python3 -ErrorAction SilentlyContinue
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

function Invoke-Runner {
    param([string[]]$Arguments)

    $lines = & $HostExe -NoProfile -ExecutionPolicy Bypass -File $Runner @Arguments 2>&1
    $code = $LASTEXITCODE
    $text = ($lines | Out-String)

    return [pscustomobject]@{
        Output = $text
        Code = $code
    }
}

function Invoke-InstalledRunner {
    param([string[]]$Arguments)

    $target = Join-Path (Join-Path $TempHome "bin") "coderun.ps1"
    $lines = & $HostExe -NoProfile -ExecutionPolicy Bypass -File $target @Arguments 2>&1
    $code = $LASTEXITCODE
    $text = ($lines | Out-String)

    return [pscustomobject]@{
        Output = $text
        Code = $code
    }
}

function New-FakeTool {
    param(
        [string]$Name,
        [int]$ExitCode = 0
    )

    if ($IsWindowsHost) {
        $content = @"
@echo off
echo $Name^|%* >>"%SHIM_LOG%"
echo $($Name.ToUpperInvariant()):%*
exit /b $ExitCode
"@

        Set-Content -LiteralPath (Join-Path $FakeBin "$Name.cmd") -Value $content -Encoding ASCII
    }
    else {
        $content = @"
#!/bin/bash
printf '%s|%s\n' '$Name' "`$*" >> "`$SHIM_LOG"
echo "$($Name.ToUpperInvariant()):`$*"
exit $ExitCode
"@

        $path = Join-Path $FakeBin $Name
        Set-Content -LiteralPath $path -Value $content -Encoding ASCII
        & chmod 755 $path
    }
}

function Remove-FakeTool {
    param([string]$Name)

    if ($IsWindowsHost) {
        Remove-Item -LiteralPath (Join-Path $FakeBin "$Name.cmd") -Force -ErrorAction SilentlyContinue
    }
    else {
        Remove-Item -LiteralPath (Join-Path $FakeBin $Name) -Force -ErrorAction SilentlyContinue
    }
}

function Reset-InstalledRunner {
    $target = Join-Path (Join-Path $TempHome "bin") "coderun.ps1"
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $target) | Out-Null
    Copy-Item -LiteralPath $Runner -Destination $target -Force
}

function Get-TargetVersion {
    $target = Join-Path (Join-Path $TempHome "bin") "coderun.ps1"
    $match = Select-String -LiteralPath $target -Pattern '^\$CoderunVersion\s*=\s*"([0-9]+\.[0-9]+\.[0-9]+)"' | Select-Object -First 1

    if ($null -eq $match) {
        return ""
    }

    return $match.Matches[0].Groups[1].Value
}

function Write-ServerFile {
    param(
        [string]$RelativePath,
        [string]$Content
    )

    $path = Join-Path $ServeRoot $RelativePath
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $path) | Out-Null
    [System.IO.File]::WriteAllText($path, $Content)
}

function Write-Candidate {
    param([string]$CandidateVersion)

    $content = (Get-Content -LiteralPath $Runner -Raw).Replace(
        "`$CoderunVersion = `"$Version`"",
        "`$CoderunVersion = `"$CandidateVersion`""
    )

    Write-ServerFile "v9.9.9/windows/coderun.ps1" $content
    $hash = (Get-FileHash -LiteralPath (Join-Path $ServeRoot "v9.9.9/windows/coderun.ps1") -Algorithm SHA256).Hash.ToLowerInvariant()
    Write-ServerFile "v9.9.9/SHA256SUMS" "$hash  windows/coderun.ps1`n"
}

function Start-UpdateServer {
    param([string]$Python)

    $listener = New-Object System.Net.Sockets.TcpListener([System.Net.IPAddress]::Loopback, 0)
    $listener.Start()
    $port = ([System.Net.IPEndPoint]$listener.LocalEndpoint).Port
    $listener.Stop()

    $startArgs = @{
        FilePath = $Python
        ArgumentList = @("-m", "http.server", "$port", "--bind", "127.0.0.1", "--directory", $ServeRoot)
        PassThru = $true
    }

    if ($IsWindowsHost) {
        $startArgs.WindowStyle = "Hidden"
    }

    $process = Start-Process @startArgs

    Start-Sleep -Milliseconds 700

    return [pscustomobject]@{
        Process = $process
        Url = "http://127.0.0.1:$port"
    }
}

New-Item -ItemType Directory -Force -Path $FakeBin, $Work | Out-Null
New-Item -ItemType File -Force -Path $ShimLog | Out-Null
$TempHome = Join-Path $TempRoot "home"
$ServeRoot = Join-Path $TempRoot "serve"
New-Item -ItemType Directory -Force -Path $TempHome, $ServeRoot | Out-Null

$env:NO_COLOR = "1"
$env:PATH = "$FakeBin$PathSeparator$OriginalPath"
$env:SHIM_LOG = $ShimLog

try {
    $tools = @(
        "gcc", "g++", "python", "Rscript", "java", "javac", "rustc", "node", "tsx",
        "go", "php", "ruby", "bash", "swift", "swiftc", "kotlinc", "lua", "perl",
        "julia", "dart", "elixir", "zig", "nim", "gfortran", "fpc", "crystal",
        "dotnet", "bun", "deno"
    )

    foreach ($tool in $tools) {
        New-FakeTool $tool
    }

    # -----------------------------------------------------------------------
    # Version, help, list, check
    # -----------------------------------------------------------------------

    $result = Invoke-Runner @("--version")
    Assert-Equal "version" "coderun $Version" $result.Output.Trim()

    $result = Invoke-Runner @("--help")
    Assert-Contains "help shows argument forwarding" "program args" $result.Output
    Assert-Contains "help shows new languages" "F#" $result.Output

    $result = Invoke-Runner @("--list")
    Assert-Contains "list shows C#" "C#" $result.Output
    Assert-Contains "list shows F#" "F#" $result.Output

    $result = Invoke-Runner @("--list", "--verbose")
    Assert-Contains "verbose list shows installed" "installed" $result.Output

    $result = Invoke-Runner @("--check", "--strict")
    Assert-Equal "strict check with all shims" "0" "$($result.Code)"

    Remove-FakeTool "zig"
    $result = Invoke-Runner @("--check")
    Assert-Equal "default check exits 0 with missing tool" "0" "$($result.Code)"
    Assert-Contains "default check reports missing tool" "missing: zig" $result.Output

    $result = Invoke-Runner @("--check", "zig")
    Assert-Equal "targeted check exits 1 when missing" "1" "$($result.Code)"

    $result = Invoke-Runner @("--check", "--strict")
    Assert-Equal "strict check exits 1 when missing" "1" "$($result.Code)"
    New-FakeTool "zig"

    $result = Invoke-Runner @("--check", "python")
    Assert-Equal "targeted check exits 0" "0" "$($result.Code)"

    # -----------------------------------------------------------------------
    # Argument forwarding and runtimes
    # -----------------------------------------------------------------------

    $pythonFile = Join-Path $Work "args.py"
    Set-Content -LiteralPath $pythonFile -Value "print('hello')" -Encoding ASCII

    $result = Invoke-Runner @($pythonFile, "--verbose", "a b")
    Assert-Equal "python receives arguments" "0" "$($result.Code)"
    Assert-Contains "python output has forwarded arguments" "PYTHON:$pythonFile --verbose a b" $result.Output

    $result = Invoke-Runner @($pythonFile, "--list")
    if (-not $result.Output.Contains("Supported languages:")) {
        Write-Pass "forwarded --list is not parsed by coderun"
    }
    else {
        Write-Fail "forwarded --list is not parsed by coderun"
    }

    $result = Invoke-Runner @("--time", $pythonFile, "x")
    Assert-Contains "time reports elapsed" "coderun: " $result.Output

    $jsFile = Join-Path $Work "app.js"
    $tsFile = Join-Path $Work "app.ts"
    Set-Content -LiteralPath $jsFile -Value "console.log('js')" -Encoding ASCII
    Set-Content -LiteralPath $tsFile -Value "console.log('ts')" -Encoding ASCII

    $result = Invoke-Runner @("--runtime", "bun", $jsFile, "arg")
    Assert-Contains "bun runtime dispatches" "BUN:run $jsFile arg" $result.Output

    $result = Invoke-Runner @("--runtime", "deno", $tsFile, "arg")
    Assert-Contains "deno runtime dispatches" "DENO:run $tsFile arg" $result.Output

    $result = Invoke-Runner @("--runtime", "node", $tsFile, "arg")
    Assert-Contains "node runtime dispatches" "NODE:$tsFile arg" $result.Output

    $result = Invoke-Runner @("--runtime", "bun", $pythonFile)
    Assert-Equal "runtime rejects non-JS/TS" "1" "$($result.Code)"

    # -----------------------------------------------------------------------
    # Compile, clean, output
    # -----------------------------------------------------------------------

    $cFile = Join-Path $Work "main.c"
    Set-Content -LiteralPath $cFile -Value "int main(void) { return 0; }" -Encoding ASCII

    $result = Invoke-Runner @("--compile", $cFile)
    Assert-Equal "compile exits 0" "0" "$($result.Code)"
    Assert-Contains "compile reports artifact" "Compiled $cFile" $result.Output

    $result = Invoke-Runner @("--quiet", "--compile", $cFile)
    if (-not $result.Output.Contains("Compiled ")) {
        Write-Pass "quiet compile suppresses coderun output"
    }
    else {
        Write-Fail "quiet compile suppresses coderun output" $result.Output
    }

    $result = Invoke-Runner @("--compile", $cFile, "extra")
    Assert-Equal "compile rejects program arguments" "1" "$($result.Code)"

    $result = Invoke-Runner @("--clean", $cFile)
    Assert-Equal "clean exits 0" "0" "$($result.Code)"

    $result = Invoke-Runner @("-o", (Join-Path $Work "app"), "--compile", $cFile)
    Assert-Equal "custom output compile exits 0" "0" "$($result.Code)"

    # -----------------------------------------------------------------------
    # Every language routes to the expected tool
    # -----------------------------------------------------------------------

    $dispatch = @(
        @("py", "PYTHON:", "python"),
        @("R", "RSCRIPT:", "Rscript"),
        @("js", "NODE:", "node"),
        @("ts", "TSX:", "tsx"),
        @("php", "PHP:", "php"),
        @("rb", "RUBY:", "ruby"),
        @("sh", "BASH:", "bash"),
        @("lua", "LUA:", "lua"),
        @("pl", "PERL:", "perl"),
        @("jl", "JULIA:", "julia"),
        @("dart", "DART:", "dart"),
        @("exs", "ELIXIR:", "elixir"),
        @("cs", "DOTNET:", "dotnet"),
        @("fsx", "DOTNET:", "dotnet"),
        @("java", "JAVA:", "java"),
        @("c", "GCC:", "gcc"),
        @("cpp", "G++:", "g++"),
        @("rs", "RUSTC:", "rustc"),
        @("go", "GO:", "go"),
        @("swift", "SWIFTC:", "swift"),
        @("kt", "KOTLINC:", "kotlinc"),
        @("zig", "ZIG:", "zig"),
        @("nim", "NIM:", "nim"),
        @("f90", "GFORTRAN:", "gfortran"),
        @("pas", "FPC:", "fpc"),
        @("cr", "CRYSTAL:", "crystal")
    )

    foreach ($case in $dispatch) {
        $extension = $case[0]
        $marker = $case[1]
        $sample = Join-Path $Work "dispatch-$extension.$extension"
        Set-Content -LiteralPath $sample -Value "sample" -Encoding ASCII

        if ($extension -in @("c", "cpp", "rs", "go", "swift", "kt", "zig", "nim", "f90", "pas", "cr")) {
            $result = Invoke-Runner @("--compile", $sample)
        }
        else {
            $result = Invoke-Runner @($sample)
        }

        Assert-Contains "dispatch .$extension" $marker $result.Output
    }

    # -----------------------------------------------------------------------
    # Completions and usage errors
    # -----------------------------------------------------------------------

    foreach ($shell in @("bash", "zsh", "fish", "powershell")) {
        $result = Invoke-Runner @("--completions", $shell)
        Assert-Equal "completions $shell exits 0" "0" "$($result.Code)"
        Assert-Contains "completions $shell mentions coderun" "coderun" $result.Output
    }

    $result = Invoke-Runner @("--compile")
    Assert-Equal "compile without file exits 1" "1" "$($result.Code)"

    $result = Invoke-Runner @("--clean")
    Assert-Equal "clean without file exits 1" "1" "$($result.Code)"

    $missing = Join-Path $Work "missing.py"
    $result = Invoke-Runner @($missing)
    Assert-Equal "missing file exits 1" "1" "$($result.Code)"

    # -----------------------------------------------------------------------
    # Update flow against a local server
    # -----------------------------------------------------------------------

    $python = $RealPython

    if ($null -ne $python -and -not [string]::IsNullOrWhiteSpace($python.Source)) {
        Write-ServerFile "main/VERSION" "$Version`n"
        Write-Candidate "9.9.9"
        $server = Start-UpdateServer $python.Source
        $env:CODERUN_RAW_BASE = $server.Url
        $env:USERPROFILE = $TempHome

        Reset-InstalledRunner
        $target = Join-Path (Join-Path $TempHome "bin") "coderun.ps1"
        $before = (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash
        $result = Invoke-InstalledRunner @("--update")
        Assert-Equal "up to date exits 0" "0" "$($result.Code)"
        Assert-Contains "up to date message" "coderun is up to date ($Version)." $result.Output
        $after = (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash
        Assert-Equal "up to date leaves target unchanged" $before $after

        Write-ServerFile "main/VERSION" "9.9.9`n"
        $result = Invoke-InstalledRunner @("--update")
        Assert-Equal "update exits 0" "0" "$($result.Code)"
        Assert-Contains "update reports new version" "coderun updated successfully to 9.9.9." $result.Output
        Assert-Equal "update installs new version" "9.9.9" (Get-TargetVersion)

        Write-ServerFile "main/VERSION" "banana`n"
        Reset-InstalledRunner
        $before = (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash
        $result = Invoke-InstalledRunner @("--update")
        Assert-Equal "invalid version exits 1" "1" "$($result.Code)"
        Assert-Contains "invalid version message" "Error: could not read the latest version." $result.Output
        $after = (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash
        Assert-Equal "invalid version leaves target unchanged" $before $after

        Write-ServerFile "main/VERSION" "9.9.9`n"
        Remove-Item -LiteralPath (Join-Path (Join-Path (Join-Path $ServeRoot "v9.9.9") "windows") "coderun.ps1") -Force
        Reset-InstalledRunner
        $result = Invoke-InstalledRunner @("--update")
        Assert-Equal "update download failure exits 1" "1" "$($result.Code)"

        Write-Candidate "9.9.9"
        Remove-Item -LiteralPath (Join-Path (Join-Path $ServeRoot "v9.9.9") "SHA256SUMS") -Force
        $result = Invoke-InstalledRunner @("--update")
        Assert-Equal "missing checksums exits 1" "1" "$($result.Code)"

        Write-ServerFile "v9.9.9/SHA256SUMS" (("0" * 64) + "  windows/coderun.ps1`n")
        $result = Invoke-InstalledRunner @("--update")
        Assert-Equal "bad checksum exits 1" "1" "$($result.Code)"
        Assert-Contains "bad checksum message" "checksum verification failed" $result.Output

        Write-Candidate "8.8.8"
        $result = Invoke-InstalledRunner @("--update")
        Assert-Equal "version mismatch exits 1" "1" "$($result.Code)"
        Assert-Contains "version mismatch message" "does not match 9.9.9" $result.Output

        Write-Candidate "9.9.9"
        $result = Invoke-InstalledRunner @("--update")
        Assert-Equal "update recovers after failures" "0" "$($result.Code)"
    }
    else {
        Write-Host "SKIP: Python was not found; update tests were skipped."
    }
}
finally {
    if ($null -ne $Server) {
        Stop-Process -Id $Server.Process.Id -Force -ErrorAction SilentlyContinue
    }

    $env:PATH = $OriginalPath
    $env:USERPROFILE = $OriginalUserProfile
    $env:CODERUN_RAW_BASE = $OriginalRawBase
    $env:SHIM_LOG = $null
    Remove-Item -LiteralPath $TempRoot -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host ""
Write-Host "Passed: $Pass  Failed: $Fail"
if ($Fail -ne 0) {
    exit 1
}
