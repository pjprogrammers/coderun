param(
    [Parameter(Position=0)]
    [string]$File
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($File)) {
    Write-Host "Usage: coderun <file>"
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
