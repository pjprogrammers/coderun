# =============================================================================
# 40-info.ps1 - --info support
#
# Prints the environment details users need when reporting a problem.
# =============================================================================

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
