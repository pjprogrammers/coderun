# shellcheck shell=bash
# shellcheck disable=SC2034
# =============================================================================
# 30-languages.sh - Language registry, lookup, and dependency checks
#
# The LANGUAGES table is the single source of truth for supported languages.
# Every other module asks this file to translate an extension, language name,
# or tool name into a language record.
#
# Record format:
#   id|display name|extensions|type|required tools
#
# Extensions and tools are space-separated. The first extension spelling is
# used for display.
# =============================================================================

LANGUAGES=(
    "c|C|c|compiled|$C_COMPILER"
    "cpp|C++|cpp|compiled|$CPP_COMPILER"
    "python|Python|py|interpreted|python3"
    "r|R|r R|interpreted|Rscript"
    "java|Java|java|compiled|java javac"
    "rust|Rust|rs|compiled|rustc"
    "javascript|JavaScript|js|interpreted|node"
    "typescript|TypeScript|ts|interpreted|tsx"
    "go|Go|go|compiled|go"
    "php|PHP|php|interpreted|php"
    "ruby|Ruby|rb|interpreted|ruby"
    "bash|Bash|sh|interpreted|bash"
    "swift|Swift|swift|compiled|swift swiftc"
    "kotlin|Kotlin|kt|compiled|kotlinc java"
    "lua|Lua|lua|interpreted|lua"
    "perl|Perl|pl|interpreted|perl"
    "julia|Julia|jl|interpreted|julia"
    "dart|Dart|dart|interpreted|dart"
    "elixir|Elixir|exs|interpreted|elixir"
    "zig|Zig|zig|compiled|zig"
    "nim|Nim|nim|compiled|nim"
    "fortran|Fortran|f90 f95 f03 f08 for f|compiled|gfortran"
    "pascal|Pascal|pas|compiled|fpc"
    "crystal|Crystal|cr|compiled|crystal"
    "csharp|C#|cs|interpreted|dotnet"
    "fsharp|F#|fsx fs|interpreted|dotnet"
)

LANGUAGE_COUNT="${#LANGUAGES[@]}"

# Populated by missing_tools. Callers must read it immediately after the call.
MISSING_TOOLS=""

# Populated by find_language and resolve_extension.
LANG_ID=""
LANG_NAME=""
LANG_TYPE=""
LANG_TOOLS=""

# Store a language record in the shared LANG_* variables.
set_language() {
    LANG_ID="$1"
    LANG_NAME="$2"
    LANG_TYPE="$3"
    LANG_TOOLS="$4"
}

# Find the first missing command from a space-separated tool list.
# Sets MISSING_TOOLS to a space-separated list (empty when everything exists).
missing_tools() {
    local tools="$1"
    local cmd
    local missing=""

    for cmd in $tools; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing="$missing $cmd"
        fi
    done

    MISSING_TOOLS="${missing# }"
}

# Turn "py R" into ".py, .R".
format_extensions() {
    local exts="$1"
    local ext
    local result=""

    for ext in $exts; do
        if [ -z "$result" ]; then
            result=".$ext"
        else
            result="$result, .$ext"
        fi
    done

    printf '%s' "$result"
}

# Print the language table. With verbose=1, also report whether each
# language's required tools are installed.
show_languages() {
    local verbose="$1"
    local spec id name exts type tools status

    echo "Supported languages:"
    echo

    if [ "$verbose" -eq 1 ]; then
        printf '  %-12s %-25s %-12s %s\n' "Language" "Extensions" "Type" "Status"
    else
        printf '  %-12s %-25s %s\n' "Language" "Extensions" "Type"
    fi

    for spec in "${LANGUAGES[@]}"; do
        IFS='|' read -r id name exts type tools <<< "$spec"

        if [ "$verbose" -eq 1 ]; then
            missing_tools "$tools"
            if [ -z "$MISSING_TOOLS" ]; then
                status="installed"
            else
                status="missing: $MISSING_TOOLS"
            fi
            printf '  %-12s %-25s %-12s %s\n' "$name" "$(format_extensions "$exts")" "$type" "$status"
        else
            printf '  %-12s %-25s %s\n' "$name" "$(format_extensions "$exts")" "$type"
        fi
    done
}

# Resolve a language id, display name, extension, or tool name.
#
# Examples: "python", "Python", "py", ".py", and "python3" all resolve to
# Python. On success the LANG_* variables are set and the function returns 0.
find_language() {
    local target
    local spec id name exts type tools
    local ext

    target="$(lowercase "$1")"
    target="${target#.}"

    # Common aliases that are not language ids or extensions.
    case "$target" in
        golang) target="go" ;;
        js) target="javascript" ;;
        ts) target="typescript" ;;
        cxx) target="cpp" ;;
        py) target="python" ;;
    esac

    for spec in "${LANGUAGES[@]}"; do
        IFS='|' read -r id name exts type tools <<< "$spec"

        if [ "$(lowercase "$id")" = "$target" ] || [ "$(lowercase "$name")" = "$target" ]; then
            set_language "$id" "$name" "$type" "$tools"
            return 0
        fi

        for ext in $exts; do
            if [ "$(lowercase "$ext")" = "$target" ]; then
                set_language "$id" "$name" "$type" "$tools"
                return 0
            fi
        done

        for ext in $tools; do
            if [ "$(lowercase "$ext")" = "$target" ]; then
                set_language "$id" "$name" "$type" "$tools"
                return 0
            fi
        done
    done

    return 1
}

# Resolve a file extension (without the leading dot) to a language record.
resolve_extension() {
    local target
    local spec id name exts type tools
    local ext

    target="$(lowercase "$1")"

    for spec in "${LANGUAGES[@]}"; do
        IFS='|' read -r id name exts type tools <<< "$spec"

        for ext in $exts; do
            if [ "$(lowercase "$ext")" = "$target" ]; then
                set_language "$id" "$name" "$type" "$tools"
                return 0
            fi
        done
    done

    return 1
}

# Check one language or every language.
#
# With no target, the check is informational and exits 0 unless strict=1.
# With a target, the check fails when that language is unknown or incomplete.
check_dependencies() {
    local target="$1"
    local strict="$2"
    local spec id name exts type tools
    local available=0
    local failures=0

    if [ -n "$target" ]; then
        if ! find_language "$target"; then
            echo "Unknown language: $target"
            echo "Run 'coderun --list' to see supported languages."
            return 1
        fi

        missing_tools "$LANG_TOOLS"
        if [ -z "$MISSING_TOOLS" ]; then
            printf '%s: ok\n' "$LANG_NAME"
            return 0
        fi

        printf '%s: missing: %s\n' "$LANG_NAME" "$MISSING_TOOLS"
        return 1
    fi

    echo "Checking required compilers and runtimes:"
    echo

    for spec in "${LANGUAGES[@]}"; do
        IFS='|' read -r id name exts type tools <<< "$spec"
        missing_tools "$tools"

        if [ -z "$MISSING_TOOLS" ]; then
            printf '  %-13s ok\n' "$name"
            available=$((available + 1))
        else
            printf '  %-13s missing: %s\n' "$name" "$MISSING_TOOLS"
            failures=$((failures + 1))
        fi
    done

    echo
    echo "$available of $LANGUAGE_COUNT language toolchains are available."

    if [ "$strict" -eq 1 ] && [ "$failures" -ne 0 ]; then
        echo "Some dependencies are missing. Install the missing tools and try again."
        return 1
    fi

    if [ "$strict" -eq 0 ]; then
        echo "Run 'coderun --check <language>' to require a specific toolchain."
    fi

    return 0
}
