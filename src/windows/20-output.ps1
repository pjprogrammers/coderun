# =============================================================================
# 20-output.ps1 - Informational output and --help
#
# Keep the help text in sync with the Unix runner and the README. The tests
# assert that key options and languages are mentioned.
# =============================================================================

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
