# =============================================================================
# 50-update.ps1 - Update, version check, and uninstall support
#
# All network access lives in this module. Updates are verified in three ways
# before the installed runner is replaced:
#   1. The downloaded file must look like a coderun PowerShell script.
#   2. Its embedded version must match the announced release.
#   3. Its SHA-256 hash must match the published SHA256SUMS entry.
# =============================================================================

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

        $firstCodeLine = Get-Content -LiteralPath $temp |
            Where-Object { $_ -notmatch '^\s*#' -and $_ -notmatch '^\s*$' } |
            Select-Object -First 1

        if ($firstCodeLine -notmatch '^\s*param\(') {
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
