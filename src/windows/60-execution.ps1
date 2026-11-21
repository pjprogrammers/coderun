# =============================================================================
# 60-execution.ps1 - Tool checks, compilation, and cleanup
#
# This module owns everything that produces or removes files on disk. It
# relies on the variables resolved by the CLI module:
#   $Language, $File, $Directory, $Base, $Extension, $OutputOpt, $HasOutput
# =============================================================================

function Assert-Tool {
    param([string]$Tool)

    if (-not (Get-Command $Tool -ErrorAction SilentlyContinue)) {
        Write-Host "Error: $Tool was not found. Run 'coderun --check' to see missing tools."
        exit 127
    }
}

# Resolve a custom -o path, adding the language-appropriate suffix when the
# user did not provide an extension.
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

# Decide where the current language's artifact should be written.
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

# Compile the current source file. Exits with the compiler's status on failure.
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

# Remove one artifact and record the outcome.
function Remove-Artifact([string]$Path) {
    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        Remove-Item -LiteralPath $Path -Force
        Write-Info "Removed $Path"
        $script:Cleaned = $true
    }
}

# Remove every artifact that the current language can generate for the source
# file, including custom output paths and Java inner classes.
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
