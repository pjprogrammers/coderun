# =============================================================================
# 10-languages.ps1 - Language registry, lookup, and dependency checks
#
# $Languages is the single source of truth for supported languages. Every
# other module asks this file to translate an extension, language name, or
# tool name into a language record.
# =============================================================================

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

# Turn a list of extensions into ".py, .pyw" style text.
function Get-ExtensionDisplay {
    param($Extensions)

    return (($Extensions | ForEach-Object { ".$_" }) -join ", ")
}

# Return the subset of tools that are not on PATH.
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

# Print the language table. With -Verbose, also report tool status.
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

# Resolve a language id, display name, extension, or tool name.
# Returns $null when the target is unknown.
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

# Resolve a file extension (without the leading dot) to a language record.
function Resolve-Extension {
    param([string]$Extension)

    return Find-Language $Extension
}

# Check one language or every language. Returns the process exit code.
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
