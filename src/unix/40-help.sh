# shellcheck shell=bash
# =============================================================================
# 40-help.sh - The --help text
#
# Keep this text in sync with the README and with the Windows runner. The
# tests assert that key options and languages are mentioned.
# =============================================================================

show_help() {
    echo "coderun $CODERUN_VERSION"
    echo
    cat <<'EOF'
Usage:
  coderun [options] <file> [program args...]
  coderun --compile <file>
  coderun --clean <file>
  coderun -o <output> <file> [program args...]
  coderun --check [language] [--strict]

Run source files in 26 languages with one command.
Everything after <file> is passed to the program unchanged.

Help:
  -h, --help           Show this help message
  -v, --version        Show the installed version

Information:
      --list           List supported languages
      --list --verbose List languages and whether their tools are installed
      --check          Check required compilers and runtimes (exit 0)
      --check <lang>   Check one language (exit 1 when it is missing)
      --check --strict Exit 1 when any dependency is missing
      --info           Show system and installation information
      --check-update   Check for a newer coderun release

Maintenance:
      --update         Update coderun to the latest version
      --uninstall      Remove coderun from this system
      --completions <shell>
                       Print completions (bash, zsh, fish, powershell)

Execution:
      --compile        Compile without running
      --clean          Remove generated build artifacts
  -o, --output <file>  Set the output artifact for compiled languages
      --runtime <name> Use node, bun, or deno for JavaScript/TypeScript
      --time           Report elapsed time after running or compiling
  -q, --quiet          Suppress coderun's own informational messages

Supported languages:
  C (.c), C++ (.cpp), Python (.py), R (.R, .r), Java (.java),
  Rust (.rs), JavaScript (.js), TypeScript (.ts), Go (.go), PHP (.php),
  Ruby (.rb), Bash (.sh), Swift (.swift), Kotlin (.kt), Lua (.lua),
  Perl (.pl), Julia (.jl), Dart (.dart), Elixir (.exs), Zig (.zig),
  Nim (.nim), Fortran (.f90), Pascal (.pas), Crystal (.cr), C# (.cs),
  F# (.fsx, .fs)

Examples:
  coderun main.cpp
  coderun main.py --verbose
  coderun main.cpp input.txt
  coderun --compile main.cpp
  coderun -o app main.cpp --port 8080
  coderun --runtime bun app.ts
  coderun --clean main.cpp
  coderun --check python
  coderun --check --strict

Note: The required compiler or runtime must be installed and on PATH.
EOF
}
