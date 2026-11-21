# =============================================================================
# 00-header.ps1 - Script parameters, version, and shared configuration
#
# This module is concatenated first. The generated windows/coderun.ps1 must
# keep param() as its first statement (comments are allowed before it).
# =============================================================================

param()

$ErrorActionPreference = "Stop"

# Keep in sync with the VERSION file. scripts/release.sh updates this line.
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

# Set by -q/--quiet. Informational output goes through Write-Info.
$Quiet = $false
