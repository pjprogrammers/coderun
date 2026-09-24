param(
    [Parameter(Mandatory=$true)]
    [string]$File
)

if (!(Test-Path $File -PathType Leaf)) {
    Write-Host "Error: file not found: $File"
    exit 1
}

$Directory = Split-Path $File -Parent

if ([string]::IsNullOrEmpty($Directory)) {
    $Directory = "."
}

$Name = Split-Path $File -Leaf
$Base = [System.IO.Path]::GetFileNameWithoutExtension($Name)
$Extension = [System.IO.Path]::GetExtension($Name).ToLower()

switch ($Extension) {
    ".cpp" {
        g++ $File -o "$Directory\$Base.exe"

        if ($LASTEXITCODE -eq 0) {
            & "$Directory\$Base.exe"
        }
    }

    ".c" {
        gcc $File -o "$Directory\$Base.exe"

        if ($LASTEXITCODE -eq 0) {
            & "$Directory\$Base.exe"
        }
    }

    ".py" {
        python $File
    }

    default {
        Write-Host "Unsupported file type: $Extension"
        Write-Host "Supported: .py .cpp .c"
        exit 1
    }
}
