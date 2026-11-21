# =============================================================================
# 70-cli.ps1 - Command-line parsing, validation, and dispatch
#
# This module is the control centre. It fills the shared state that the
# language, update, and execution modules consume:
#   $Mode, $Action, $OutputOpt, $RuntimeOpt, $CheckTarget, $CheckStrict,
#   $ListVerbose, $TimeIt, $CompletionShell, $File, $ProgramArgs
#
# Validation adds:
#   $Directory, $Name, $Base, $Extension, $Language, $HasOutput
# =============================================================================

$RawArgs = @($args)
$Mode = "run"
$Action = ""
$OutputOpt = ""
$RuntimeOpt = ""
$CheckTarget = ""
$CheckStrict = $false
$ListVerbose = $false
$TimeIt = $false
$CompletionShell = ""
$File = ""
$ProgramArgs = @()

function Set-Action {
    param([string]$NewAction)

    if (-not [string]::IsNullOrWhiteSpace($script:Action) -and $script:Action -ne $NewAction) {
        Write-Host "Error: --$($script:Action) and --$NewAction cannot be combined."
        exit 1
    }

    $script:Action = $NewAction
}

$index = 0

while ($index -lt $RawArgs.Count) {
    if (-not [string]::IsNullOrWhiteSpace($File)) {
        if ($ProgramArgs.Count -eq 0 -and [string]$RawArgs[$index] -eq "--") {
            $index++
        }

        if ($index -lt $RawArgs.Count) {
            $ProgramArgs = @($RawArgs[$index..($RawArgs.Count - 1)])
        }

        break
    }

    $argument = [string]$RawArgs[$index]
    $lower = $argument.ToLowerInvariant()

    switch ($lower) {
        "-h" {
            Show-Help
            exit 0
        }

        "--help" {
            Show-Help
            exit 0
        }

        "-v" {
            Write-Host "coderun $CoderunVersion"
            exit 0
        }

        "--version" {
            Write-Host "coderun $CoderunVersion"
            exit 0
        }

        "--list" {
            Set-Action "list"
        }

        "--verbose" {
            $ListVerbose = $true
        }

        "--check" {
            Set-Action "check"
        }

        "--strict" {
            $CheckStrict = $true
        }

        "--info" {
            Set-Action "info"
        }

        "--check-update" {
            Set-Action "check-update"
        }

        "--update" {
            Set-Action "update"
        }

        "--uninstall" {
            Set-Action "uninstall"
        }

        "--completions" {
            if ($index + 1 -ge $RawArgs.Count -or [string]::IsNullOrWhiteSpace([string]$RawArgs[$index + 1])) {
                Write-Host "Error: --completions requires a shell name."
                exit 1
            }

            Set-Action "completions"
            $CompletionShell = [string]$RawArgs[$index + 1]
            $index++
        }

        "--compile" {
            if ($Mode -ne "run" -and $Mode -ne "compile") {
                Write-Host "Error: --compile and --clean cannot be used together."
                exit 1
            }
            $Mode = "compile"
        }

        "--clean" {
            if ($Mode -ne "run" -and $Mode -ne "clean") {
                Write-Host "Error: --compile and --clean cannot be used together."
                exit 1
            }
            $Mode = "clean"
        }

        "-o" {
            if ($index + 1 -ge $RawArgs.Count -or [string]::IsNullOrWhiteSpace([string]$RawArgs[$index + 1])) {
                Write-Host "Error: $argument requires an output path."
                exit 1
            }
            $OutputOpt = [string]$RawArgs[$index + 1]
            $index++
        }

        "--output" {
            if ($index + 1 -ge $RawArgs.Count -or [string]::IsNullOrWhiteSpace([string]$RawArgs[$index + 1])) {
                Write-Host "Error: $argument requires an output path."
                exit 1
            }
            $OutputOpt = [string]$RawArgs[$index + 1]
            $index++
        }

        "--runtime" {
            if ($index + 1 -ge $RawArgs.Count -or [string]::IsNullOrWhiteSpace([string]$RawArgs[$index + 1])) {
                Write-Host "Error: --runtime requires a value: node, bun, or deno."
                exit 1
            }
            $RuntimeOpt = [string]$RawArgs[$index + 1]
            $index++
        }

        "--time" {
            $TimeIt = $true
        }

        "-q" {
            $Quiet = $true
        }

        "--quiet" {
            $Quiet = $true
        }

        "--" {
            $index++

            if ($index -lt $RawArgs.Count) {
                $File = [string]$RawArgs[$index]
                $index++
            }

            if ($index -lt $RawArgs.Count) {
                $ProgramArgs = @($RawArgs[$index..($RawArgs.Count - 1)])
            }

            $index = $RawArgs.Count
        }

        default {
            if ($argument.StartsWith("-")) {
                Write-Host "Unknown option: $argument"
                Write-Host "Try 'coderun --help' for more information."
                exit 1
            }

            if ($Action -eq "check" -and [string]::IsNullOrWhiteSpace($CheckTarget)) {
                $CheckTarget = $argument
            }
            else {
                $File = $argument
            }
        }
    }

    $index++
}

# ---------------------------------------------------------------------------
# Top-level actions
# ---------------------------------------------------------------------------

if (-not [string]::IsNullOrWhiteSpace($Action)) {
    if ($Mode -ne "run") {
        Write-Host "Error: --$Action cannot be combined with --compile or --clean."
        exit 1
    }

    if (-not [string]::IsNullOrWhiteSpace($OutputOpt)) {
        Write-Host "Error: --$Action cannot be combined with -o/--output."
        exit 1
    }

    if ($Action -ne "check" -and $Action -ne "list" -and -not [string]::IsNullOrWhiteSpace($File)) {
        Write-Host "Error: unexpected argument: $File"
        exit 1
    }

    switch ($Action) {
        "list" {
            if (-not [string]::IsNullOrWhiteSpace($File) -or -not [string]::IsNullOrWhiteSpace($CheckTarget)) {
                $unexpected = $File
                if ([string]::IsNullOrWhiteSpace($unexpected)) {
                    $unexpected = $CheckTarget
                }
                Write-Host "Error: unexpected argument: $unexpected"
                exit 1
            }

            Show-Languages $ListVerbose
            exit 0
        }

        "check" {
            if (-not [string]::IsNullOrWhiteSpace($File)) {
                Write-Host "Error: unexpected argument: $File"
                exit 1
            }

            $result = Invoke-Check $CheckTarget $CheckStrict
            exit $result
        }

        "info" {
            Show-Info
            exit 0
        }

        "check-update" {
            Check-ForUpdate
        }

        "update" {
            Update-Coderun
            exit 0
        }

        "uninstall" {
            Uninstall-Coderun
            exit 0
        }

        "completions" {
            Show-Completions $CompletionShell
            exit 0
        }
    }
}

# ---------------------------------------------------------------------------
# Flag and source-file validation
# ---------------------------------------------------------------------------

if ($ListVerbose) {
    Write-Host "Error: --verbose can only be used with --list."
    exit 1
}

if ($CheckStrict) {
    Write-Host "Error: --strict can only be used with --check."
    exit 1
}

if (($Mode -eq "compile" -or $Mode -eq "clean") -and [string]::IsNullOrWhiteSpace($File)) {
    Write-Host "Error: --$Mode requires a source file."
    exit 1
}

if ([string]::IsNullOrWhiteSpace($File)) {
    if (-not [string]::IsNullOrWhiteSpace($OutputOpt)) {
        Write-Host "Error: -o/--output requires a source file."
        exit 1
    }

    Show-Help
    exit 1
}

if (!(Test-Path -LiteralPath $File -PathType Leaf)) {
    Write-Host "Error: file not found: $File"
    exit 1
}

$File = (Resolve-Path -LiteralPath $File).Path
$Directory = Split-Path -Parent $File
$Name = Split-Path -Leaf $File
$Base = [System.IO.Path]::GetFileNameWithoutExtension($Name)
$Extension = [System.IO.Path]::GetExtension($Name).ToLowerInvariant()
$Language = Resolve-Extension $Extension.TrimStart(".")

if ($null -eq $Language) {
    Write-Host "Unsupported file type: $Extension"
    Write-Host "Run 'coderun --list' to see supported languages."
    exit 1
}

if (-not [string]::IsNullOrWhiteSpace($RuntimeOpt)) {
    if (@("node", "bun", "deno") -notcontains $RuntimeOpt.ToLowerInvariant()) {
        Write-Host "Error: unknown runtime: $RuntimeOpt"
        Write-Host "Supported runtimes: node, bun, deno."
        exit 1
    }

    if ($Language.Id -ne "javascript" -and $Language.Id -ne "typescript") {
        Write-Host "Error: --runtime is only supported for JavaScript and TypeScript."
        exit 1
    }

    $RuntimeOpt = $RuntimeOpt.ToLowerInvariant()
}

$HasOutput = -not [string]::IsNullOrWhiteSpace($OutputOpt)

if ($HasOutput) {
    if ($Language.Id -eq "java") {
        Write-Host "Error: -o/--output is not supported for Java."
        exit 1
    }

    if ($Language.Type -ne "compiled") {
        Write-Host "Error: -o/--output is only supported for compiled languages."
        exit 1
    }

    if ([System.IO.Path]::GetFullPath($OutputOpt) -eq $File) {
        Write-Host "Error: output path must not be the source file."
        exit 1
    }
}

$script:Artifact = ""
$script:Cleaned = $false

# ---------------------------------------------------------------------------
# Clean and compile modes
# ---------------------------------------------------------------------------

if ($Mode -eq "clean") {
    if ($ProgramArgs.Count -gt 0) {
        Write-Host "Error: --clean does not accept program arguments."
        exit 1
    }

    Invoke-Clean
    exit 0
}

if ($Mode -eq "compile") {
    if ($ProgramArgs.Count -gt 0) {
        Write-Host "Error: --compile does not accept program arguments."
        exit 1
    }

    if ($Language.Type -ne "compiled") {
        Write-Host "Error: cannot compile $Extension files; this language is interpreted."
        Write-Host "Use 'coderun `"$File`"' to run it directly."
        exit 1
    }

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    Invoke-Compile
    $stopwatch.Stop()

    if ($TimeIt) {
        [Console]::Error.WriteLine("coderun: {0:F3}s" -f $stopwatch.Elapsed.TotalSeconds)
    }

    if ($Language.Id -eq "java") {
        Write-Info "Compiled $File -> $Directory (Java class files)"
    }
    else {
        Write-Info "Compiled $File -> $script:Artifact"
    }

    exit 0
}

# ---------------------------------------------------------------------------
# Run mode
# ---------------------------------------------------------------------------

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$exitCode = 0

switch ($Language.Id) {
    "python" {
        Assert-Tool "python"
        & python $File @ProgramArgs
        $exitCode = $LASTEXITCODE
    }

    "r" {
        Assert-Tool "Rscript"
        & Rscript $File @ProgramArgs
        $exitCode = $LASTEXITCODE
    }

    "javascript" {
        $runtime = $RuntimeOpt
        if ([string]::IsNullOrWhiteSpace($runtime)) {
            $runtime = "node"
        }

        Assert-Tool $runtime

        if ($runtime -eq "bun") {
            & bun run $File @ProgramArgs
        }
        elseif ($runtime -eq "deno") {
            & deno run $File @ProgramArgs
        }
        else {
            & node $File @ProgramArgs
        }

        $exitCode = $LASTEXITCODE
    }

    "typescript" {
        $runtime = $RuntimeOpt
        if ([string]::IsNullOrWhiteSpace($runtime)) {
            $runtime = "tsx"
        }

        Assert-Tool $runtime

        if ($runtime -eq "bun") {
            & bun run $File @ProgramArgs
        }
        elseif ($runtime -eq "deno") {
            & deno run $File @ProgramArgs
        }
        elseif ($runtime -eq "node") {
            & node $File @ProgramArgs
        }
        else {
            & tsx $File @ProgramArgs
        }

        $exitCode = $LASTEXITCODE
    }

    "php" {
        Assert-Tool "php"
        & php $File @ProgramArgs
        $exitCode = $LASTEXITCODE
    }

    "ruby" {
        Assert-Tool "ruby"
        & ruby $File @ProgramArgs
        $exitCode = $LASTEXITCODE
    }

    "bash" {
        Assert-Tool "bash"
        $bashFile = $File -replace '\\', '/'
        & bash $bashFile @ProgramArgs
        $exitCode = $LASTEXITCODE
    }

    "lua" {
        Assert-Tool "lua"
        & lua $File @ProgramArgs
        $exitCode = $LASTEXITCODE
    }

    "perl" {
        Assert-Tool "perl"
        & perl $File @ProgramArgs
        $exitCode = $LASTEXITCODE
    }

    "julia" {
        Assert-Tool "julia"
        & julia $File @ProgramArgs
        $exitCode = $LASTEXITCODE
    }

    "dart" {
        Assert-Tool "dart"
        & dart run $File @ProgramArgs
        $exitCode = $LASTEXITCODE
    }

    "elixir" {
        Assert-Tool "elixir"
        & elixir $File @ProgramArgs
        $exitCode = $LASTEXITCODE
    }

    "csharp" {
        Assert-Tool "dotnet"
        $dotnetArgs = @("run", $File)

        if ($ProgramArgs.Count -gt 0) {
            $dotnetArgs += "--"
            $dotnetArgs += $ProgramArgs
        }

        & dotnet @dotnetArgs
        $exitCode = $LASTEXITCODE
    }

    "fsharp" {
        Assert-Tool "dotnet"
        & dotnet fsi $File @ProgramArgs
        $exitCode = $LASTEXITCODE
    }

    "java" {
        Assert-Tool "java"
        & java $File @ProgramArgs
        $exitCode = $LASTEXITCODE
    }

    "cpp" {
        Invoke-Compile
        & $script:Artifact @ProgramArgs
        $exitCode = $LASTEXITCODE
    }

    "c" {
        Invoke-Compile
        & $script:Artifact @ProgramArgs
        $exitCode = $LASTEXITCODE
    }

    "rust" {
        Invoke-Compile
        & $script:Artifact @ProgramArgs
        $exitCode = $LASTEXITCODE
    }

    "fortran" {
        Invoke-Compile
        & $script:Artifact @ProgramArgs
        $exitCode = $LASTEXITCODE
    }

    "pascal" {
        Invoke-Compile
        & $script:Artifact @ProgramArgs
        $exitCode = $LASTEXITCODE
    }

    "kotlin" {
        Invoke-Compile
        Assert-Tool "java"
        & java -jar $script:Artifact @ProgramArgs
        $exitCode = $LASTEXITCODE
    }

    "zig" {
        if ($HasOutput) {
            Invoke-Compile
            & $script:Artifact @ProgramArgs
            $exitCode = $LASTEXITCODE
        }
        else {
            Assert-Tool "zig"
            $zigArgs = @("run", $File, "--")
            $zigArgs += $ProgramArgs
            & zig @zigArgs
            $exitCode = $LASTEXITCODE
        }
    }

    "nim" {
        if ($HasOutput) {
            Invoke-Compile
            & $script:Artifact @ProgramArgs
            $exitCode = $LASTEXITCODE
        }
        else {
            Assert-Tool "nim"
            $nimArgs = @("r", $File, "--")
            $nimArgs += $ProgramArgs
            & nim @nimArgs
            $exitCode = $LASTEXITCODE
        }
    }

    "crystal" {
        if ($HasOutput) {
            Invoke-Compile
            & $script:Artifact @ProgramArgs
            $exitCode = $LASTEXITCODE
        }
        else {
            Assert-Tool "crystal"
            $crystalArgs = @("run", $File, "--")
            $crystalArgs += $ProgramArgs
            & crystal @crystalArgs
            $exitCode = $LASTEXITCODE
        }
    }

    "go" {
        if ($HasOutput) {
            Invoke-Compile
            & $script:Artifact @ProgramArgs
            $exitCode = $LASTEXITCODE
        }
        else {
            Assert-Tool "go"
            & go run $File @ProgramArgs
            $exitCode = $LASTEXITCODE
        }
    }

    "swift" {
        if ($HasOutput) {
            Invoke-Compile
            & $script:Artifact @ProgramArgs
            $exitCode = $LASTEXITCODE
        }
        else {
            Assert-Tool "swift"
            & swift $File @ProgramArgs
            $exitCode = $LASTEXITCODE
        }
    }
}

$stopwatch.Stop()

if ($TimeIt) {
    [Console]::Error.WriteLine("coderun: {0:F3}s" -f $stopwatch.Elapsed.TotalSeconds)
}

exit $exitCode
