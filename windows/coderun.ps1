param(
    [Parameter(Position=0)]
    [string]$File,

    [Alias("h")]
    [switch]$Help,

    [Alias("v")]
    [switch]$Version,

    [switch]$Update,

    [switch]$Uninstall,

    [Parameter(ValueFromRemainingArguments=$true)]
    [string[]]$Remaining
)

$ErrorActionPreference = "Stop"

# Keep in sync with the VERSION file.
$CoderunVersion = "2.1.0"

$UpdateUrl = "https://raw.githubusercontent.com/pjprogrammers/coderun/main/windows/coderun.ps1"

function Show-Help {
    Write-Host "coderun $CoderunVersion"
    Write-Host ""
    Write-Host "Usage: coderun <file>"
    Write-Host ""
    Write-Host "Run source files in 14 languages with one command."
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -h, --help       Show this help message"
    Write-Host "  -v, --version    Show the installed version"
    Write-Host "  --update         Update coderun to the latest version"
    Write-Host "  --uninstall      Remove coderun from this system"
    Write-Host ""
    Write-Host "Supported languages:"
    Write-Host "  C (.c), C++ (.cpp), Python (.py), R (.R, .r), Java (.java),"
    Write-Host "  Rust (.rs), JavaScript (.js), TypeScript (.ts), Go (.go), PHP (.php),"
    Write-Host "  Ruby (.rb), Bash (.sh), Swift (.swift), Kotlin (.kt)"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  coderun main.cpp"
    Write-Host "  coderun main.py"
    Write-Host "  coderun Main.java"
    Write-Host ""
    Write-Host "Note: The required compiler or runtime must be installed and on PATH."
}

function Update-Coderun {
    $InstallDir = Join-Path $env:USERPROFILE "bin"
    $Target = Join-Path $InstallDir "coderun.ps1"

    if (!(Test-Path -LiteralPath $Target -PathType Leaf)) {
        Write-Host "Error: coderun is not installed at $Target."
        Write-Host "Run .\install.ps1 from the repository first."
        exit 1
    }

    $Temp = Join-Path $InstallDir "coderun.ps1.tmp"

    Write-Host "Updating coderun..."

    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $UpdateUrl -OutFile $Temp -UseBasicParsing

        $FirstLine = Get-Content -LiteralPath $Temp -TotalCount 1

        if ($FirstLine -notmatch '^param\(') {
            throw "Downloaded file does not look like a valid coderun script."
        }

        Move-Item -LiteralPath $Temp -Destination $Target -Force
    }
    catch {
        Remove-Item -LiteralPath $Temp -Force -ErrorAction SilentlyContinue
        Write-Host "Error: update failed: $($_.Exception.Message)"
        exit 1
    }

    Write-Host "coderun updated successfully."
}

function Uninstall-Coderun {
    $InstallDir = Join-Path $env:USERPROFILE "bin"
    $Files = @(
        (Join-Path $InstallDir "coderun.ps1"),
        (Join-Path $InstallDir "coderun.cmd")
    )

    $Removed = $false

    foreach ($FilePath in $Files) {
        if (Test-Path -LiteralPath $FilePath -PathType Leaf) {
            Remove-Item -LiteralPath $FilePath -Force
            Write-Host "Removed $FilePath"
            $Removed = $true
        }
    }

    $UserPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $InstallDirExists = Test-Path -LiteralPath $InstallDir
    $HasOtherFiles = $false

    if ($InstallDirExists) {
        $HasOtherFiles = [bool](Get-ChildItem -LiteralPath $InstallDir -Force)
    }

    if ($HasOtherFiles) {
        Write-Host "Kept $InstallDir in PATH because it contains other files."
    }
    else {
        if ($UserPath) {
            $Entries = $UserPath -split ";" | Where-Object {
                $_ -ne "" -and $_.TrimEnd("\") -ne $InstallDir.TrimEnd("\")
            }
            $NewPath = $Entries -join ";"

            if ($NewPath -ne $UserPath) {
                [Environment]::SetEnvironmentVariable("Path", $NewPath, "User")
                Write-Host "Removed $InstallDir from the User PATH"
            }
        }

        if ($InstallDirExists) {
            Remove-Item -LiteralPath $InstallDir -Force
        }
    }

    if (-not $Removed) {
        Write-Host "coderun was not installed at $InstallDir."
    }
    else {
        Write-Host "coderun uninstalled successfully."
        Write-Host "Open a new terminal to finish."
    }
}

if ($Version) {
    Write-Host "coderun $CoderunVersion"
    exit 0
}

if ($Help) {
    Show-Help
    exit 0
}

if ($Update) {
    Update-Coderun
    exit 0
}

if ($Uninstall) {
    Uninstall-Coderun
    exit 0
}

# Fallback for hosts that pass --long-options as plain arguments.
$Option = $File

if ([string]::IsNullOrWhiteSpace($Option) -and $Remaining.Count -gt 0) {
    $Option = $Remaining[0]
}

if ($Option) {
    switch ($Option.ToLowerInvariant()) {
        "-h" {
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

        "--help" {
            Show-Help
            exit 0
        }

        "--update" {
            Update-Coderun
            exit 0
        }

        "--uninstall" {
            Uninstall-Coderun
            exit 0
        }
    }
}

if ([string]::IsNullOrWhiteSpace($File)) {
    if ($Remaining.Count -gt 0 -and $Remaining[0].StartsWith("-")) {
        Write-Host "Unknown option: $($Remaining[0])"
        Write-Host "Try 'coderun --help' for more information."
        exit 1
    }

    Show-Help
    exit 1
}

if ($File.StartsWith("-")) {
    Write-Host "Unknown option: $File"
    Write-Host "Try 'coderun --help' for more information."
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
$Extension = [System.IO.Path]::GetExtension($Name)
$Extension = $Extension.ToLowerInvariant()

$Executable = Join-Path $Directory $Base
$Jar = Join-Path $Directory "$Base.jar"

switch ($Extension) {
    ".cpp" {
        & g++ $File -o "$Executable.exe"

        if ($LASTEXITCODE -ne 0) {
            exit $LASTEXITCODE
        }

        & "$Executable.exe"
        exit $LASTEXITCODE
    }

    ".c" {
        & gcc $File -o "$Executable.exe"

        if ($LASTEXITCODE -ne 0) {
            exit $LASTEXITCODE
        }

        & "$Executable.exe"
        exit $LASTEXITCODE
    }

    ".py" {
        & python $File
        exit $LASTEXITCODE
    }

    ".r" {
        & Rscript $File
        exit $LASTEXITCODE
    }

    ".java" {
        & java $File
        exit $LASTEXITCODE
    }

    ".rs" {
        & rustc $File -o "$Executable.exe"

        if ($LASTEXITCODE -ne 0) {
            exit $LASTEXITCODE
        }

        & "$Executable.exe"
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

    ".go" {
        & go run $File
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
        $BashFile = $File -replace '\\', '/'
        & bash $BashFile
        exit $LASTEXITCODE
    }

    ".swift" {
        & swift $File
        exit $LASTEXITCODE
    }

    ".kt" {
        & kotlinc $File -include-runtime -d "$Jar"

        if ($LASTEXITCODE -ne 0) {
            exit $LASTEXITCODE
        }

        & java -jar "$Jar"
        exit $LASTEXITCODE
    }

    default {
        Write-Host "Unsupported file type: $Extension"
        Write-Host "Supported: .py .cpp .c .R .r .java .rs .js .ts .go .php .rb .sh .swift .kt"
        exit 1
    }
}
