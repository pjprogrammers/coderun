param()

$ErrorActionPreference = "Stop"

# Keep in sync with the VERSION file.
$CoderunVersion = "2.4.0"

# Override for testing or mirrors. The runner appends /main or /v<version>.
if ($env:CODERUN_RAW_BASE) {
    $CoderunRawBase = $env:CODERUN_RAW_BASE
}
else {
    $CoderunRawBase = "https://raw.githubusercontent.com/pjprogrammers/coderun"
}

$RunnerPath = "windows/coderun.ps1"
$CCompiler = "gcc"
$CppCompiler = "g++"

# Language metadata: Id, Name, Extensions, Type, Tools.
$Languages = @(
    [pscustomobject]@{ Id = "c"; Name = "C"; Extensions = @("c"); Type = "compiled"; Tools = @("gcc") },
    [pscustomobject]@{ Id = "cpp"; Name = "C++"; Extensions = @("cpp"); Type = "compiled"; Tools = @("g++") },
    [pscustomobject]@{ Id = "python"; Name = "Python"; Extensions = @("py"); Type = "interpreted"; Tools = @("python") },
    [pscustomobject]@{ Id = "r"; Name = "R"; Extensions = @("r", "R"); Type = "interpreted"; Tools = @("Rscript") },
    [pscustomobject]@{ Id = "java"; Name = "Java"; Extensions = @("java"); Type = "compiled"; Tools = @("java", "javac") },
    [pscustomobject]@{ Id = "rust"; Name = "Rust"; Extensions = @("rs"); Type = "compiled"; Tools = @("rustc") },
    [pscustomobject]@{ Id = "javascript"; Name = "JavaScript"; Extensions = @("js"); Type = "interpreted"; Tools = @("node") },
    [pscustomobject]@{ Id = "typescript"; Name = "TypeScript"; Extensions = @("ts"); Type = "interpreted"; Tools = @("tsx") },
    [pscustomobject]@{ Id = "go"; Name = "Go"; Extensions = @("go"); Type = "compiled"; Tools = @("go") },
    [pscustomobject]@{ Id = "php"; Name = "PHP"; Extensions = @("php"); Type = "interpreted"; Tools = @("php") },
    [pscustomobject]@{ Id = "ruby"; Name = "Ruby"; Extensions = @("rb"); Type = "interpreted"; Tools = @("ruby") },
    [pscustomobject]@{ Id = "bash"; Name = "Bash"; Extensions = @("sh"); Type = "interpreted"; Tools = @("bash") },
    [pscustomobject]@{ Id = "swift"; Name = "Swift"; Extensions = @("swift"); Type = "compiled"; Tools = @("swift", "swiftc") },
    [pscustomobject]@{ Id = "kotlin"; Name = "Kotlin"; Extensions = @("kt"); Type = "compiled"; Tools = @("kotlinc", "java") },
    [pscustomobject]@{ Id = "lua"; Name = "Lua"; Extensions = @("lua"); Type = "interpreted"; Tools = @("lua") },
    [pscustomobject]@{ Id = "perl"; Name = "Perl"; Extensions = @("pl"); Type = "interpreted"; Tools = @("perl") },
    [pscustomobject]@{ Id = "julia"; Name = "Julia"; Extensions = @("jl"); Type = "interpreted"; Tools = @("julia") },
    [pscustomobject]@{ Id = "dart"; Name = "Dart"; Extensions = @("dart"); Type = "interpreted"; Tools = @("dart") },
    [pscustomobject]@{ Id = "elixir"; Name = "Elixir"; Extensions = @("exs"); Type = "interpreted"; Tools = @("elixir") },
    [pscustomobject]@{ Id = "zig"; Name = "Zig"; Extensions = @("zig"); Type = "compiled"; Tools = @("zig") },
    [pscustomobject]@{ Id = "nim"; Name = "Nim"; Extensions = @("nim"); Type = "compiled"; Tools = @("nim") },
    [pscustomobject]@{ Id = "fortran"; Name = "Fortran"; Extensions = @("f90", "f95", "f03", "f08", "for", "f"); Type = "compiled"; Tools = @("gfortran") },
    [pscustomobject]@{ Id = "pascal"; Name = "Pascal"; Extensions = @("pas"); Type = "compiled"; Tools = @("fpc") },
    [pscustomobject]@{ Id = "crystal"; Name = "Crystal"; Extensions = @("cr"); Type = "compiled"; Tools = @("crystal") },
    [pscustomobject]@{ Id = "csharp"; Name = "C#"; Extensions = @("cs"); Type = "interpreted"; Tools = @("dotnet") },
    [pscustomobject]@{ Id = "fsharp"; Name = "F#"; Extensions = @("fsx", "fs"); Type = "interpreted"; Tools = @("dotnet") }
)

$Quiet = $false

function Write-Info {
    param([string]$Message)

    if (-not $script:Quiet) {
        Write-Host $Message
    }
}

function Show-Help {
    Write-Host "coderun $CoderunVersion"
    Write-Host ""
    Write-Host "Usage:"
    Write-Host "  coderun [options] <file> [program args...]"
    Write-Host "  coderun --compile <file>"
    Write-Host "  coderun --clean <file>"
    Write-Host "  coderun -o <output> <file> [program args...]"
    Write-Host "  coderun --check [language] [--strict]"
    Write-Host ""
    Write-Host "Run source files in 26 languages with one command."
    Write-Host "Everything after <file> is passed to the program unchanged."
    Write-Host ""
    Write-Host "Help:"
    Write-Host "  -h, --help           Show this help message"
    Write-Host "  -v, --version        Show the installed version"
    Write-Host ""
    Write-Host "Information:"
    Write-Host "      --list           List supported languages"
    Write-Host "      --list --verbose List languages and whether their tools are installed"
    Write-Host "      --check          Check required compilers and runtimes (exit 0)"
    Write-Host "      --check <lang>   Check one language (exit 1 when it is missing)"
    Write-Host "      --check --strict Exit 1 when any dependency is missing"
    Write-Host "      --info           Show system and installation information"
    Write-Host "      --check-update   Check for a newer coderun release"
    Write-Host ""
    Write-Host "Maintenance:"
    Write-Host "      --update         Update coderun to the latest version"
    Write-Host "      --uninstall      Remove coderun from this system"
    Write-Host "      --completions <shell>"
    Write-Host "                       Print completions (bash, zsh, fish, powershell)"
    Write-Host ""
    Write-Host "Execution:"
    Write-Host "      --compile        Compile without running"
    Write-Host "      --clean          Remove generated build artifacts"
    Write-Host "  -o, --output <file>  Set the output artifact for compiled languages"
    Write-Host "      --runtime <name> Use node, bun, or deno for JavaScript/TypeScript"
    Write-Host "      --time           Report elapsed time after running or compiling"
    Write-Host "  -q, --quiet          Suppress coderun's own informational messages"
    Write-Host ""
    Write-Host "Supported languages:"
    Write-Host "  C (.c), C++ (.cpp), Python (.py), R (.R, .r), Java (.java),"
    Write-Host "  Rust (.rs), JavaScript (.js), TypeScript (.ts), Go (.go), PHP (.php),"
    Write-Host "  Ruby (.rb), Bash (.sh), Swift (.swift), Kotlin (.kt), Lua (.lua),"
    Write-Host "  Perl (.pl), Julia (.jl), Dart (.dart), Elixir (.exs), Zig (.zig),"
    Write-Host "  Nim (.nim), Fortran (.f90), Pascal (.pas), Crystal (.cr), C# (.cs),"
    Write-Host "  F# (.fsx, .fs)"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  coderun main.cpp"
    Write-Host "  coderun main.py --verbose"
    Write-Host "  coderun main.cpp input.txt"
    Write-Host "  coderun --compile main.cpp"
    Write-Host "  coderun -o app main.cpp --port 8080"
    Write-Host "  coderun --runtime bun app.ts"
    Write-Host "  coderun --clean main.cpp"
    Write-Host "  coderun --check python"
    Write-Host "  coderun --check --strict"
    Write-Host ""
    Write-Host "Note: The required compiler or runtime must be installed and on PATH."
}

function Get-ExtensionDisplay {
    param($Extensions)

    return (($Extensions | ForEach-Object { ".$_" }) -join ", ")
}

function Get-MissingTools {
    param($Tools)

    $missing = @()

    foreach ($tool in $Tools) {
        if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
            $missing += $tool
        }
    }

    return $missing
}

function Show-Languages {
    param([bool]$Verbose)

    Write-Host "Supported languages:"
    Write-Host ""

    if ($Verbose) {
        Write-Host ("  {0,-12} {1,-36} {2,-12} {3}" -f "Language", "Extensions", "Type", "Status")
    }
    else {
        Write-Host ("  {0,-12} {1,-36} {2}" -f "Language", "Extensions", "Type")
    }

    foreach ($language in $Languages) {
        $extensions = Get-ExtensionDisplay $language.Extensions

        if ($Verbose) {
            $missing = @(Get-MissingTools $language.Tools)

            if ($missing.Count -eq 0) {
                $status = "installed"
            }
            else {
                $status = "missing: $($missing -join ' ')"
            }

            Write-Host ("  {0,-12} {1,-36} {2,-12} {3}" -f $language.Name, $extensions, $language.Type, $status)
        }
        else {
            Write-Host ("  {0,-12} {1,-36} {2}" -f $language.Name, $extensions, $language.Type)
        }
    }
}

function Find-Language {
    param([string]$Target)

    $normalized = $Target.ToLowerInvariant().TrimStart(".")

    switch ($normalized) {
        "golang" { $normalized = "go" }
        "js" { $normalized = "javascript" }
        "ts" { $normalized = "typescript" }
        "cxx" { $normalized = "cpp" }
        "py" { $normalized = "python" }
    }

    foreach ($language in $Languages) {
        if ($language.Id.ToLowerInvariant() -eq $normalized -or
            $language.Name.ToLowerInvariant() -eq $normalized) {
            return $language
        }

        foreach ($extension in $language.Extensions) {
            if ($extension.ToLowerInvariant() -eq $normalized) {
                return $language
            }
        }

        foreach ($tool in $language.Tools) {
            if ($tool.ToLowerInvariant() -eq $normalized) {
                return $language
            }
        }
    }

    return $null
}

function Resolve-Extension {
    param([string]$Extension)

    return Find-Language $Extension
}

function Invoke-Check {
    param(
        [string]$Target,
        [bool]$Strict
    )

    if (-not [string]::IsNullOrWhiteSpace($Target)) {
        $language = Find-Language $Target

        if ($null -eq $language) {
            Write-Host "Unknown language: $Target"
            Write-Host "Run 'coderun --list' to see supported languages."
            return 1
        }

        $missing = @(Get-MissingTools $language.Tools)

        if ($missing.Count -eq 0) {
            Write-Host "$($language.Name): ok"
            return 0
        }

        Write-Host "$($language.Name): missing: $($missing -join ' ')"
        return 1
    }

    Write-Host "Checking required compilers and runtimes:"
    Write-Host ""

    $available = 0
    $failures = 0

    foreach ($language in $Languages) {
        $missing = @(Get-MissingTools $language.Tools)

        if ($missing.Count -eq 0) {
            Write-Host ("  {0,-13} ok" -f $language.Name)
            $available++
        }
        else {
            Write-Host ("  {0,-13} missing: {1}" -f $language.Name, ($missing -join " "))
            $failures++
        }
    }

    Write-Host ""
    Write-Host "$available of $($Languages.Count) language toolchains are available."

    if ($Strict -and $failures -gt 0) {
        Write-Host "Some dependencies are missing. Install the missing tools and try again."
        return 1
    }

    if (-not $Strict) {
        Write-Host "Run 'coderun --check <language>' to require a specific toolchain."
    }

    return 0
}

function Show-Completions {
    param([string]$Shell)

    switch ($Shell.ToLowerInvariant()) {
        "bash" {
            Write-Output @'
# bash completion for coderun
_coderun() {
    local cur opts
    cur="${COMP_WORDS[COMP_CWORD]}"
    opts="-h --help -v --version --list --verbose --check --strict --info --check-update --update --uninstall --compile --clean -o --output --runtime --time -q --quiet --completions"
    if [ "$COMP_CWORD" -eq 1 ]; then
        COMPREPLY=( $(compgen -W "$opts" -- "$cur") )
    fi
    COMPREPLY+=( $(compgen -f -- "$cur") )
}
complete -F _coderun coderun
'@
        }

        "zsh" {
            Write-Output @'
#compdef coderun
_coderun() {
    _arguments \
        '(-h --help)'{-h,--help}'[show help]' \
        '(-v --version)'{-v,--version}'[show version]' \
        '--list[list supported languages]' \
        '--verbose[show tool status with --list]' \
        '--check[check toolchains]' \
        '--strict[fail when tools are missing]' \
        '--info[show system information]' \
        '--check-update[check for a newer release]' \
        '--update[update coderun]' \
        '--uninstall[remove coderun]' \
        '--compile[compile only]' \
        '--clean[remove build artifacts]' \
        '(-o --output)'{-o,--output}'[set output artifact]:file:_files' \
        '--runtime[choose JavaScript/TypeScript runtime]:runtime:(node bun deno)' \
        '--time[report elapsed time]' \
        '(-q --quiet)'{-q,--quiet}'[suppress informational messages]' \
        '--completions[print completions]:shell:(bash zsh fish powershell)' \
        '*:file:_files'
}
_coderun "$@"
'@
        }

        "fish" {
            Write-Output @'
# fish completion for coderun
complete -c coderun -f
complete -c coderun -s h -l help -d 'Show help'
complete -c coderun -s v -l version -d 'Show version'
complete -c coderun -l list -d 'List supported languages'
complete -c coderun -l verbose -d 'Show tool status with --list'
complete -c coderun -l check -d 'Check toolchains'
complete -c coderun -l strict -d 'Fail when tools are missing'
complete -c coderun -l info -d 'Show system information'
complete -c coderun -l check-update -d 'Check for updates'
complete -c coderun -l update -d 'Update coderun'
complete -c coderun -l uninstall -d 'Remove coderun'
complete -c coderun -l compile -d 'Compile only'
complete -c coderun -l clean -d 'Remove build artifacts'
complete -c coderun -s o -l output -r -d 'Set output artifact'
complete -c coderun -l runtime -r -a 'node bun deno' -d 'Choose runtime'
complete -c coderun -l time -d 'Report elapsed time'
complete -c coderun -s q -l quiet -d 'Suppress informational messages'
complete -c coderun -l completions -r -a 'bash zsh fish powershell' -d 'Print completions'
complete -c coderun -F
'@
        }

        "powershell" {
            Write-Output @'
# PowerShell completion for coderun
Register-ArgumentCompleter -Native -CommandName coderun -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)
    $options = @(
        '-h', '--help', '-v', '--version', '--list', '--verbose', '--check',
        '--strict', '--info', '--check-update', '--update', '--uninstall',
        '--compile', '--clean', '-o', '--output', '--runtime', '--time',
        '-q', '--quiet', '--completions'
    )
    $options | Where-Object { $_ -like "$wordToComplete*" } |
        ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterName', $_)
        }
}
'@
        }

        default {
            Write-Host "Error: unknown shell: $Shell"
            Write-Host "Supported shells: bash, zsh, fish, powershell."
            exit 1
        }
    }
}

function Show-Info {
    $installPath = $PSCommandPath

    if ([string]::IsNullOrWhiteSpace($installPath)) {
        $installPath = $MyInvocation.MyCommand.Path
    }

    $architecture = $env:PROCESSOR_ARCHITECTURE

    if ([string]::IsNullOrWhiteSpace($architecture)) {
        try {
            $architecture = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString()
        }
        catch {
            $architecture = "unknown"
        }
    }

    Write-Host "coderun $CoderunVersion"
    Write-Host "Install path: $installPath"
    Write-Host "Operating system: $([Environment]::OSVersion.VersionString)"
    Write-Host "Architecture: $architecture"
    Write-Host "PowerShell: $($PSVersionTable.PSVersion.ToString())"
    Write-Host "Languages: $($Languages.Count)"
    Write-Host "Runner URL: $CoderunRawBase/v$CoderunVersion/$RunnerPath"
}

function Test-VersionGreater([string]$Left, [string]$Right) {
    $leftParts = $Left.Split(".")
    $rightParts = $Right.Split(".")

    for ($i = 0; $i -lt 3; $i++) {
        $leftValue = 0
        $rightValue = 0

        if ($i -lt $leftParts.Count) {
            $leftValue = [int]$leftParts[$i]
        }

        if ($i -lt $rightParts.Count) {
            $rightValue = [int]$rightParts[$i]
        }

        if ($leftValue -gt $rightValue) {
            return $true
        }

        if ($leftValue -lt $rightValue) {
            return $false
        }
    }

    return $false
}

function Get-LatestVersion {
    $temp = Join-Path ([System.IO.Path]::GetTempPath()) "coderun-version-$PID.txt"
    $latest = $null

    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri "$CoderunRawBase/main/VERSION" -OutFile $temp -UseBasicParsing
        $latest = (Get-Content -LiteralPath $temp -Raw).Trim()
    }
    catch {
        $latest = $null
    }
    finally {
        Remove-Item -LiteralPath $temp -Force -ErrorAction SilentlyContinue
    }

    if ([string]::IsNullOrWhiteSpace($latest)) {
        Write-Host "Error: could not check for updates."
        exit 1
    }

    if ($latest -notmatch '^\d+\.\d+\.\d+$') {
        Write-Host "Error: could not read the latest version."
        exit 1
    }

    return $latest
}

function Check-ForUpdate {
    Write-Host "Current version: $CoderunVersion"
    Write-Host "Checking for updates..."

    $latest = Get-LatestVersion

    Write-Host "Latest version: $latest"

    if (Test-VersionGreater $latest $CoderunVersion) {
        Write-Host "A new version is available. Run 'coderun --update' to install it."
        exit 1
    }

    Write-Host "coderun is up to date."
    exit 0
}

function Update-Coderun {
    $installDir = Join-Path $env:USERPROFILE "bin"
    $target = Join-Path $installDir "coderun.ps1"

    if (!(Test-Path -LiteralPath $target -PathType Leaf)) {
        Write-Host "Error: coderun is not installed at $target."
        Write-Host "Run .\install.ps1 from the repository first."
        exit 1
    }

    Write-Host "Current version: $CoderunVersion"
    Write-Host "Checking for updates..."

    $latest = Get-LatestVersion

    Write-Host "Latest version: $latest"

    if (-not (Test-VersionGreater $latest $CoderunVersion)) {
        Write-Host "coderun is up to date ($CoderunVersion)."
        exit 0
    }

    $temp = Join-Path $installDir "coderun.ps1.tmp.$PID"
    $checksumTemp = Join-Path ([System.IO.Path]::GetTempPath()) "coderun-checksums-$PID.txt"

    Write-Host "Updating coderun to $latest..."

    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri "$CoderunRawBase/v$latest/$RunnerPath" -OutFile $temp -UseBasicParsing

        $firstLine = Get-Content -LiteralPath $temp -TotalCount 1

        if ($firstLine -notmatch '^param\(') {
            throw "Downloaded file does not look like a valid coderun script."
        }

        $versionMatch = Select-String -LiteralPath $temp -Pattern '^\$CoderunVersion\s*=\s*"([0-9]+\.[0-9]+\.[0-9]+)"' | Select-Object -First 1

        if ($null -eq $versionMatch -or $versionMatch.Matches[0].Groups[1].Value -ne $latest) {
            throw "Downloaded runner version does not match $latest."
        }

        Invoke-WebRequest -Uri "$CoderunRawBase/v$latest/SHA256SUMS" -OutFile $checksumTemp -UseBasicParsing
        $checksumLine = Get-Content -LiteralPath $checksumTemp |
            Where-Object { $_ -match '^\s*[0-9a-fA-F]{64}\s+windows/coderun\.ps1\s*$' } |
            Select-Object -First 1

        if ([string]::IsNullOrWhiteSpace($checksumLine)) {
            throw "SHA256SUMS does not contain windows/coderun.ps1."
        }

        $expected = ($checksumLine -split '\s+')[0].ToLowerInvariant()
        $actual = (Get-FileHash -LiteralPath $temp -Algorithm SHA256).Hash.ToLowerInvariant()

        if ($expected -ne $actual) {
            throw "Update checksum verification failed."
        }

        Move-Item -LiteralPath $temp -Destination $target -Force
    }
    catch {
        Remove-Item -LiteralPath $temp -Force -ErrorAction SilentlyContinue
        Write-Host "Error: update failed: $($_.Exception.Message)"
        exit 1
    }
    finally {
        Remove-Item -LiteralPath $checksumTemp -Force -ErrorAction SilentlyContinue
    }

    Write-Host "coderun updated successfully to $latest."
}

function Uninstall-Coderun {
    $installDir = Join-Path $env:USERPROFILE "bin"
    $files = @(
        (Join-Path $installDir "coderun.ps1"),
        (Join-Path $installDir "coderun.cmd")
    )

    $removed = $false

    foreach ($filePath in $files) {
        if (Test-Path -LiteralPath $filePath -PathType Leaf) {
            Remove-Item -LiteralPath $filePath -Force
            Write-Host "Removed $filePath"
            $removed = $true
        }
    }

    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $installDirExists = Test-Path -LiteralPath $installDir
    $hasOtherFiles = $false

    if ($installDirExists) {
        $hasOtherFiles = [bool](Get-ChildItem -LiteralPath $installDir -Force)
    }

    if ($hasOtherFiles) {
        Write-Host "Kept $installDir in PATH because it contains other files."
    }
    else {
        if ($userPath) {
            $entries = $userPath -split ";" | Where-Object {
                $_ -ne "" -and $_.TrimEnd("\") -ne $installDir.TrimEnd("\")
            }
            $newPath = $entries -join ";"

            if ($newPath -ne $userPath) {
                [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
                Write-Host "Removed $installDir from the User PATH"
            }
        }

        if ($installDirExists) {
            Remove-Item -LiteralPath $installDir -Force
        }
    }

    if (-not $removed) {
        Write-Host "coderun was not installed at $installDir."
    }
    else {
        Write-Host "coderun uninstalled successfully."
        Write-Host "Open a new terminal to finish."
    }
}

function Assert-Tool {
    param([string]$Tool)

    if (-not (Get-Command $Tool -ErrorAction SilentlyContinue)) {
        Write-Host "Error: $Tool was not found. Run 'coderun --check' to see missing tools."
        exit 127
    }
}

function Resolve-CustomArtifact([string]$Value, [string]$Extension) {
    $fullPath = [System.IO.Path]::GetFullPath($Value)

    if (-not [string]::IsNullOrEmpty([System.IO.Path]::GetExtension($fullPath))) {
        return $fullPath
    }

    if ($Extension -eq ".kt") {
        return "$fullPath.jar"
    }

    return "$fullPath.exe"
}

function Set-CompileArtifact {
    switch ($Language.Id) {
        "kotlin" {
            if ($HasOutput) {
                $script:Artifact = Resolve-CustomArtifact $OutputOpt ".kt"
            }
            else {
                $script:Artifact = Join-Path $Directory "$Base.jar"
            }
        }

        "java" {
            $script:Artifact = $Directory
        }

        default {
            if ($HasOutput) {
                $script:Artifact = Resolve-CustomArtifact $OutputOpt $Extension
            }
            else {
                $script:Artifact = Join-Path $Directory "$Base.exe"
            }
        }
    }
}

function Invoke-Compile {
    Set-CompileArtifact

    switch ($Language.Id) {
        "cpp" {
            Assert-Tool $CppCompiler
            & $CppCompiler $File -o $script:Artifact
        }

        "c" {
            Assert-Tool $CCompiler
            & $CCompiler $File -o $script:Artifact
        }

        "java" {
            Assert-Tool "javac"
            & javac $File -d $Directory
        }

        "rust" {
            Assert-Tool "rustc"
            & rustc $File -o $script:Artifact
        }

        "go" {
            Assert-Tool "go"
            & go build -o $script:Artifact $File
        }

        "swift" {
            Assert-Tool "swiftc"
            & swiftc $File -o $script:Artifact
        }

        "kotlin" {
            Assert-Tool "kotlinc"
            & kotlinc $File -include-runtime -d $script:Artifact
        }

        "zig" {
            Assert-Tool "zig"
            & zig build-exe $File "-femit-bin=$($script:Artifact)"
        }

        "nim" {
            Assert-Tool "nim"
            & nim c "--out:$($script:Artifact)" $File
        }

        "fortran" {
            Assert-Tool "gfortran"
            & gfortran $File -o $script:Artifact
        }

        "pascal" {
            Assert-Tool "fpc"
            & fpc $File "-o$($script:Artifact)"
        }

        "crystal" {
            Assert-Tool "crystal"
            & crystal build $File -o $script:Artifact
        }
    }

    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
}

function Remove-Artifact([string]$Path) {
    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        Remove-Item -LiteralPath $Path -Force
        Write-Info "Removed $Path"
        $script:Cleaned = $true
    }
}

function Invoke-Clean {
    if ($Language.Type -eq "interpreted") {
        Write-Info "No build artifacts to clean for $Extension files (interpreted language)."
        return
    }

    if ($HasOutput) {
        switch ($Language.Id) {
            "kotlin" {
                Remove-Artifact (Resolve-CustomArtifact $OutputOpt ".kt")
            }
            "java" {
            }
            default {
                Remove-Artifact (Resolve-CustomArtifact $OutputOpt $Extension)
            }
        }
    }

    switch ($Language.Id) {
        "c" {
            Remove-Artifact (Join-Path $Directory "$Base.exe")
        }

        "cpp" {
            Remove-Artifact (Join-Path $Directory "$Base.exe")
        }

        "rust" {
            Remove-Artifact (Join-Path $Directory "$Base.exe")
        }

        "go" {
            Remove-Artifact (Join-Path $Directory "$Base.exe")
        }

        "swift" {
            Remove-Artifact (Join-Path $Directory "$Base.exe")
        }

        "zig" {
            Remove-Artifact (Join-Path $Directory "$Base.exe")
            Remove-Artifact (Join-Path $Directory "$Base.o")
        }

        "nim" {
            Remove-Artifact (Join-Path $Directory "$Base.exe")
        }

        "fortran" {
            Remove-Artifact (Join-Path $Directory "$Base.exe")
        }

        "pascal" {
            Remove-Artifact (Join-Path $Directory "$Base.exe")
        }

        "crystal" {
            Remove-Artifact (Join-Path $Directory "$Base.exe")
        }

        "kotlin" {
            Remove-Artifact (Join-Path $Directory "$Base.jar")
        }

        "java" {
            Remove-Artifact (Join-Path $Directory "$Base.class")

            Get-ChildItem -LiteralPath $Directory -Filter "$Base`$*.class" -File -ErrorAction SilentlyContinue |
                ForEach-Object { Remove-Artifact $_.FullName }
        }
    }

    if (-not $script:Cleaned) {
        Write-Info "No build artifacts found for $File."
    }
}

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------

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
