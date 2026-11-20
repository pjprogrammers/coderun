param(
    [Parameter(Position=0)]
    [string]$File,

    [Alias("h")]
    [switch]$Help,

    [Alias("v")]
    [switch]$Version,

    [switch]$List,

    [switch]$Check,

    [switch]$Info,

    [Alias("check-update")]
    [switch]$CheckUpdate,

    [switch]$Update,

    [switch]$Uninstall,

    [switch]$Compile,

    [switch]$Clean,

    [Alias("o")]
    [string]$Output,

    [Parameter(ValueFromRemainingArguments=$true)]
    [string[]]$Remaining
)

$ErrorActionPreference = "Stop"

# Keep in sync with the VERSION file.
$CoderunVersion = "2.3.1"

$UpdateUrl = "https://raw.githubusercontent.com/pjprogrammers/coderun/main/windows/coderun.ps1"
$VersionUrl = "https://raw.githubusercontent.com/pjprogrammers/coderun/main/VERSION"

$CompiledExtensions = @(".c", ".cpp", ".java", ".rs", ".go", ".swift", ".kt")
$InterpretedExtensions = @(".py", ".r", ".js", ".ts", ".php", ".rb", ".sh", ".lua", ".pl", ".jl", ".dart", ".exs")

function Show-Help {
    Write-Host "coderun $CoderunVersion"
    Write-Host ""
    Write-Host "Usage:"
    Write-Host "  coderun <file>"
    Write-Host "  coderun --compile <file>"
    Write-Host "  coderun --clean <file>"
    Write-Host "  coderun -o <output> <file>"
    Write-Host ""
    Write-Host "Run source files in 19 languages with one command."
    Write-Host ""
    Write-Host "Help:"
    Write-Host "  -h, --help           Show this help message"
    Write-Host "  -v, --version        Show the installed version"
    Write-Host ""
    Write-Host "Information:"
    Write-Host "      --list           List supported languages"
    Write-Host "      --check          Check required compilers and runtimes"
    Write-Host "      --info           Show system and installation information"
    Write-Host "      --check-update   Check for a newer coderun release"
    Write-Host ""
    Write-Host "Maintenance:"
    Write-Host "      --update         Update coderun to the latest version"
    Write-Host "      --uninstall      Remove coderun from this system"
    Write-Host ""
    Write-Host "Execution:"
    Write-Host "      --compile        Compile without running"
    Write-Host "      --clean          Remove generated build artifacts"
    Write-Host "  -o, --output <file>  Set the output artifact for compiled languages"
    Write-Host ""
    Write-Host "Supported languages:"
    Write-Host "  C (.c), C++ (.cpp), Python (.py), R (.R, .r), Java (.java),"
    Write-Host "  Rust (.rs), JavaScript (.js), TypeScript (.ts), Go (.go), PHP (.php),"
    Write-Host "  Ruby (.rb), Bash (.sh), Swift (.swift), Kotlin (.kt), Lua (.lua),"
    Write-Host "  Perl (.pl), Julia (.jl), Dart (.dart), Elixir (.exs)"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  coderun main.cpp"
    Write-Host "  coderun main.py"
    Write-Host "  coderun --compile main.cpp"
    Write-Host "  coderun -o app main.cpp"
    Write-Host "  coderun --clean main.cpp"
    Write-Host ""
    Write-Host "Note: The required compiler or runtime must be installed and on PATH."
}

function Show-Languages {
    Write-Host "Supported languages:"
    Write-Host ""
    Write-Host ("  {0,-12} {1,-14} {2}" -f "Language", "Extensions", "Type")
    Write-Host ("  {0,-12} {1,-14} {2}" -f "C", ".c", "compiled")
    Write-Host ("  {0,-12} {1,-14} {2}" -f "C++", ".cpp", "compiled")
    Write-Host ("  {0,-12} {1,-14} {2}" -f "Python", ".py", "interpreted")
    Write-Host ("  {0,-12} {1,-14} {2}" -f "R", ".r, .R", "interpreted")
    Write-Host ("  {0,-12} {1,-14} {2}" -f "Java", ".java", "compiled")
    Write-Host ("  {0,-12} {1,-14} {2}" -f "Rust", ".rs", "compiled")
    Write-Host ("  {0,-12} {1,-14} {2}" -f "JavaScript", ".js", "interpreted")
    Write-Host ("  {0,-12} {1,-14} {2}" -f "TypeScript", ".ts", "interpreted")
    Write-Host ("  {0,-12} {1,-14} {2}" -f "Go", ".go", "compiled")
    Write-Host ("  {0,-12} {1,-14} {2}" -f "PHP", ".php", "interpreted")
    Write-Host ("  {0,-12} {1,-14} {2}" -f "Ruby", ".rb", "interpreted")
    Write-Host ("  {0,-12} {1,-14} {2}" -f "Bash", ".sh", "interpreted")
    Write-Host ("  {0,-12} {1,-14} {2}" -f "Swift", ".swift", "compiled")
    Write-Host ("  {0,-12} {1,-14} {2}" -f "Kotlin", ".kt", "compiled")
    Write-Host ("  {0,-12} {1,-14} {2}" -f "Lua", ".lua", "interpreted")
    Write-Host ("  {0,-12} {1,-14} {2}" -f "Perl", ".pl", "interpreted")
    Write-Host ("  {0,-12} {1,-14} {2}" -f "Julia", ".jl", "interpreted")
    Write-Host ("  {0,-12} {1,-14} {2}" -f "Dart", ".dart", "interpreted")
    Write-Host ("  {0,-12} {1,-14} {2}" -f "Elixir", ".exs", "interpreted")
}

function Check-Dependencies {
    $checks = @(
        @{ Name = "C"; Commands = @("gcc") },
        @{ Name = "C++"; Commands = @("g++") },
        @{ Name = "Python"; Commands = @("python") },
        @{ Name = "R"; Commands = @("Rscript") },
        @{ Name = "Java"; Commands = @("java", "javac") },
        @{ Name = "Rust"; Commands = @("rustc") },
        @{ Name = "JavaScript"; Commands = @("node") },
        @{ Name = "TypeScript"; Commands = @("tsx") },
        @{ Name = "Go"; Commands = @("go") },
        @{ Name = "PHP"; Commands = @("php") },
        @{ Name = "Ruby"; Commands = @("ruby") },
        @{ Name = "Bash"; Commands = @("bash") },
        @{ Name = "Swift"; Commands = @("swift", "swiftc") },
        @{ Name = "Kotlin"; Commands = @("kotlinc", "java") },
        @{ Name = "Lua"; Commands = @("lua") },
        @{ Name = "Perl"; Commands = @("perl") },
        @{ Name = "Julia"; Commands = @("julia") },
        @{ Name = "Dart"; Commands = @("dart") },
        @{ Name = "Elixir"; Commands = @("elixir") }
    )

    $failures = 0

    Write-Host "Checking required compilers and runtimes:"
    Write-Host ""

    foreach ($entry in $checks) {
        $missing = @()

        foreach ($command in $entry.Commands) {
            if (-not (Get-Command $command -ErrorAction SilentlyContinue)) {
                $missing += $command
            }
        }

        if ($missing.Count -eq 0) {
            Write-Host ("  {0,-13} ok" -f $entry.Name)
        }
        else {
            Write-Host ("  {0,-13} missing: {1}" -f $entry.Name, ($missing -join " "))
            $failures++
        }
    }

    Write-Host ""
    return $failures
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
        Invoke-WebRequest -Uri $VersionUrl -OutFile $temp -UseBasicParsing
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

    $temp = Join-Path $installDir "coderun.ps1.tmp"

    Write-Host "Updating coderun to $latest..."

    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $UpdateUrl -OutFile $temp -UseBasicParsing

        $firstLine = Get-Content -LiteralPath $temp -TotalCount 1

        if ($firstLine -notmatch '^param\(') {
            throw "Downloaded file does not look like a valid coderun script."
        }

        Move-Item -LiteralPath $temp -Destination $target -Force
    }
    catch {
        Remove-Item -LiteralPath $temp -Force -ErrorAction SilentlyContinue
        Write-Host "Error: update failed: $($_.Exception.Message)"
        exit 1
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
    switch ($Extension) {
        ".kt" {
            if ($HasOutput) {
                $script:Artifact = Resolve-CustomArtifact $Output ".kt"
            }
            else {
                $script:Artifact = Join-Path $Directory "$Base.jar"
            }
        }

        ".java" {
            $script:Artifact = $Directory
        }

        default {
            if ($HasOutput) {
                $script:Artifact = Resolve-CustomArtifact $Output $Extension
            }
            else {
                $script:Artifact = Join-Path $Directory "$Base.exe"
            }
        }
    }
}

function Invoke-Compile {
    Set-CompileArtifact

    switch ($Extension) {
        ".cpp" {
            & g++ $File -o $script:Artifact
        }

        ".c" {
            & gcc $File -o $script:Artifact
        }

        ".java" {
            & javac $File -d $Directory
        }

        ".rs" {
            & rustc $File -o $script:Artifact
        }

        ".go" {
            & go build -o $script:Artifact $File
        }

        ".swift" {
            & swiftc $File -o $script:Artifact
        }

        ".kt" {
            & kotlinc $File -include-runtime -d $script:Artifact
        }
    }

    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
}

function Remove-Artifact([string]$Path) {
    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        Remove-Item -LiteralPath $Path -Force
        Write-Host "Removed $Path"
        $script:Cleaned = $true
    }
}

function Invoke-Clean {
    if ($InterpretedExtensions -contains $Extension) {
        Write-Host "No build artifacts to clean for $Extension files (interpreted language)."
        return
    }

    if ($HasOutput) {
        Remove-Artifact (Resolve-CustomArtifact $Output $Extension)
    }

    switch ($Extension) {
        ".c" {
            Remove-Artifact (Join-Path $Directory "$Base.exe")
        }

        ".cpp" {
            Remove-Artifact (Join-Path $Directory "$Base.exe")
        }

        ".rs" {
            Remove-Artifact (Join-Path $Directory "$Base.exe")
        }

        ".go" {
            Remove-Artifact (Join-Path $Directory "$Base.exe")
        }

        ".swift" {
            Remove-Artifact (Join-Path $Directory "$Base.exe")
        }

        ".kt" {
            Remove-Artifact (Join-Path $Directory "$Base.jar")
        }

        ".java" {
            Remove-Artifact (Join-Path $Directory "$Base.class")

            Get-ChildItem -LiteralPath $Directory -Filter "$Base`$*.class" -File -ErrorAction SilentlyContinue |
                ForEach-Object { Remove-Artifact $_.FullName }
        }
    }

    if (-not $script:Cleaned) {
        Write-Host "No build artifacts found for $File."
    }
}

if ($Help) {
    Show-Help
    exit 0
}

if ($Version) {
    Write-Host "coderun $CoderunVersion"
    exit 0
}

if ($List) {
    Show-Languages
    exit 0
}

if ($Check) {
    $missingCount = Check-Dependencies

    if ($missingCount -eq 0) {
        Write-Host "All dependencies are available."
        exit 0
    }

    Write-Host "Some dependencies are missing. Install the missing tools and try again."
    exit 1
}

if ($Info) {
    Show-Info
    exit 0
}

if ($CheckUpdate) {
    Check-ForUpdate
}

if ($Update) {
    Update-Coderun
    exit 0
}

if ($Uninstall) {
    Uninstall-Coderun
    exit 0
}

# Fallback for hosts that pass long options as plain arguments.
$options = @()

if (-not [string]::IsNullOrWhiteSpace($File) -and $File.StartsWith("-")) {
    $options += $File
    $File = ""
}

if ($Remaining.Count -gt 0) {
    $options += @($Remaining | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
}

$unknown = @()

foreach ($option in $options) {
    switch ($option.ToLowerInvariant()) {
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
            Show-Languages
            exit 0
        }

        "--check" {
            $missingCount = Check-Dependencies

            if ($missingCount -eq 0) {
                Write-Host "All dependencies are available."
                exit 0
            }

            Write-Host "Some dependencies are missing. Install the missing tools and try again."
            exit 1
        }

        "--info" {
            Show-Info
            exit 0
        }

        "--check-update" {
            Check-ForUpdate
        }

        "--update" {
            Update-Coderun
            exit 0
        }

        "--uninstall" {
            Uninstall-Coderun
            exit 0
        }

        "--compile" {
            $Compile = $true
        }

        "--clean" {
            $Clean = $true
        }

        default {
            if (-not $option.StartsWith("-") -and [string]::IsNullOrWhiteSpace($File)) {
                $File = $option
            }
            else {
                $unknown += $option
            }
        }
    }
}

if ($unknown.Count -gt 0) {
    $firstUnknown = $unknown[0]

    if ($firstUnknown.StartsWith("-")) {
        Write-Host "Unknown option: $firstUnknown"
        Write-Host "Try 'coderun --help' for more information."
    }
    else {
        Write-Host "Error: unexpected argument: $firstUnknown"
    }

    exit 1
}

if ($Compile -and $Clean) {
    Write-Host "Error: --compile and --clean cannot be used together."
    exit 1
}

$hasOutput = -not [string]::IsNullOrWhiteSpace($Output)

if ($PSBoundParameters.ContainsKey("Output") -and -not $hasOutput) {
    Write-Host "Error: -o/--output requires an output path."
    exit 1
}

if ([string]::IsNullOrWhiteSpace($File)) {
    if ($Compile) {
        Write-Host "Error: --compile requires a source file."
        exit 1
    }

    if ($Clean) {
        Write-Host "Error: --clean requires a source file."
        exit 1
    }

    if ($hasOutput) {
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

if (($CompiledExtensions -notcontains $Extension) -and ($InterpretedExtensions -notcontains $Extension)) {
    Write-Host "Unsupported file type: $Extension"
    Write-Host "Supported: .py .cpp .c .R .r .java .rs .js .ts .go .php .rb .sh .swift .kt .lua .pl .jl .dart .exs"
    exit 1
}

if ($hasOutput) {
    if ($Extension -eq ".java") {
        Write-Host "Error: -o/--output is not supported for Java."
        exit 1
    }

    if ($InterpretedExtensions -contains $Extension) {
        Write-Host "Error: -o/--output is only supported for compiled languages."
        exit 1
    }

    if ([System.IO.Path]::GetFullPath($Output) -eq $File) {
        Write-Host "Error: output path must not be the source file."
        exit 1
    }
}

$script:Artifact = ""
$script:Cleaned = $false

if ($Clean) {
    Invoke-Clean
    exit 0
}

if ($Compile) {
    if ($InterpretedExtensions -contains $Extension) {
        Write-Host "Error: cannot compile $Extension files; this language is interpreted."
        Write-Host "Use 'coderun `"$File`"' to run it directly."
        exit 1
    }

    Invoke-Compile

    if ($Extension -eq ".java") {
        Write-Host "Compiled $File -> $Directory (Java class files)"
    }
    else {
        Write-Host "Compiled $File -> $script:Artifact"
    }

    exit 0
}

switch ($Extension) {
    ".py" {
        & python $File
        exit $LASTEXITCODE
    }

    ".r" {
        & Rscript $File
        exit $LASTEXITCODE
    }

    ".js" {
        & node $File
        exit $LASTEXITCODE
    }

    ".ts" {
        & tsx $File
        exit $LASTEXITCODE
    }

    ".php" {
        & php $File
        exit $LASTEXITCODE
    }

    ".rb" {
        & ruby $File
        exit $LASTEXITCODE
    }

    ".sh" {
        $bashFile = $File -replace '\\', '/'
        & bash $bashFile
        exit $LASTEXITCODE
    }

    ".lua" {
        & lua $File
        exit $LASTEXITCODE
    }

    ".pl" {
        & perl $File
        exit $LASTEXITCODE
    }

    ".jl" {
        & julia $File
        exit $LASTEXITCODE
    }

    ".dart" {
        & dart run $File
        exit $LASTEXITCODE
    }

    ".exs" {
        & elixir $File
        exit $LASTEXITCODE
    }

    ".java" {
        & java $File
        exit $LASTEXITCODE
    }

    ".cpp" {
        Invoke-Compile
        & $script:Artifact
        exit $LASTEXITCODE
    }

    ".c" {
        Invoke-Compile
        & $script:Artifact
        exit $LASTEXITCODE
    }

    ".rs" {
        Invoke-Compile
        & $script:Artifact
        exit $LASTEXITCODE
    }

    ".kt" {
        Invoke-Compile
        & java -jar $script:Artifact
        exit $LASTEXITCODE
    }

    ".go" {
        if ($hasOutput) {
            Invoke-Compile
            & $script:Artifact
            exit $LASTEXITCODE
        }

        & go run $File
        exit $LASTEXITCODE
    }

    ".swift" {
        if ($hasOutput) {
            Invoke-Compile
            & $script:Artifact
            exit $LASTEXITCODE
        }

        & swift $File
        exit $LASTEXITCODE
    }
}
