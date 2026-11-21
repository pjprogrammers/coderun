#!/usr/bin/env bash
#
# Build the distributable coderun runners from the modular sources.
#
# The shipped runners are single files so users can install them by copying one
# file and update them with one verified download. Maintainers edit src/ and
# run this script to regenerate the committed artifacts.
#
# Usage:
#   scripts/build.sh          Regenerate the committed runners
#   scripts/build.sh --check  Verify the committed runners are up to date

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# Order matters: modules are concatenated in this order.
UNIX_MODULES=(
    "src/unix/10-config.sh"
    "src/unix/20-output.sh"
    "src/unix/30-languages.sh"
    "src/unix/40-help.sh"
    "src/unix/50-completions.sh"
    "src/unix/60-info.sh"
    "src/unix/70-update.sh"
    "src/unix/80-compile.sh"
    "src/unix/90-run.sh"
    "src/unix/95-cli.sh"
    "src/unix/99-main.sh"
)

WINDOWS_MODULES=(
    "src/windows/00-header.ps1"
    "src/windows/10-languages.ps1"
    "src/windows/20-output.ps1"
    "src/windows/30-completions.ps1"
    "src/windows/40-info.ps1"
    "src/windows/50-update.ps1"
    "src/windows/60-execution.ps1"
    "src/windows/70-cli.ps1"
)

MODE="write"

usage() {
    cat <<'EOF'
Usage: scripts/build.sh [--check]

Builds the single-file runners from src/unix and src/windows.

  --check   Verify that the committed runners match a fresh build.
            Does not modify any files.
  -h, --help
            Show this help message.
EOF
}

case "${1:-}" in
    "")
        ;;
    --check)
        MODE="check"
        ;;
    -h|--help)
        usage
        exit 0
        ;;
    *)
        echo "Error: unknown option: $1" >&2
        usage >&2
        exit 1
        ;;
esac

TEMP_DIR="${TMPDIR:-/tmp}/coderun-build.$$"
rm -rf "$TEMP_DIR"
mkdir -p "$TEMP_DIR"
trap 'rm -rf "$TEMP_DIR"' EXIT

# Fail early with a clear message when a module is missing.
require_modules() {
    local module

    for module in "$@"; do
        if [ ! -f "$module" ]; then
            echo "Error: missing source module: $module" >&2
            exit 1
        fi
    done
}

# Write the generated-file banner shared by both runners.
write_banner() {
    local title="$1"
    local source_dir="$2"
    shift 2

    printf '# =============================================================================\n'
    printf '# %s\n' "$title"
    printf '#\n'
    printf '# GENERATED FILE - DO NOT EDIT.\n'
    printf '# Source modules live in %s/ and are concatenated by scripts/build.sh.\n' "$source_dir"
    printf '# Edit the modules, then run: ./scripts/build.sh\n'
    printf '#\n'
    printf '# Module order:\n'

    local module
    for module in "$@"; do
        printf '#   %s\n' "$module"
    done

    printf '# =============================================================================\n'
}

# Build the Unix runner. It must start with the Bash shebang on line 1.
build_unix() {
    local output="$1"
    local module

    {
        printf '#!/usr/bin/env bash\n'
        write_banner "coderun - run source files in 26 languages with one command." "src/unix" "${UNIX_MODULES[@]}"

        for module in "${UNIX_MODULES[@]}"; do
            printf '\n'
            cat "$module"
        done
    } > "$output"

    bash -n "$output"
}

# Build the Windows runner. param() must remain the first statement after the
# banner comments.
build_windows() {
    local output="$1"
    local module

    {
        write_banner "coderun - run source files in 26 languages with one command." "src/windows" "${WINDOWS_MODULES[@]}"

        for module in "${WINDOWS_MODULES[@]}"; do
            printf '\n'
            cat "$module"
        done
    } > "$output"
}

# Parse the generated PowerShell when pwsh is available. CI installs pwsh;
# local builds without it still work.
validate_powershell() {
    local file="$1"

    if ! command -v pwsh >/dev/null 2>&1; then
        return 0
    fi

    CODERUN_BUILD_FILE="$file" pwsh -NoProfile -Command '
        $errors = $null
        [System.Management.Automation.Language.Parser]::ParseFile(
            $env:CODERUN_BUILD_FILE,
            [ref]$null,
            [ref]$errors
        ) | Out-Null

        if ($errors.Count -gt 0) {
            $errors | ForEach-Object { Write-Error $_.Message }
            exit 1
        }
    '
}

# Compare a generated file with the committed artifact.
compare_file() {
    local generated="$1"
    local committed="$2"

    if ! cmp -s "$generated" "$committed"; then
        echo "Error: $committed is out of date. Run ./scripts/build.sh." >&2
        return 1
    fi
}

# Copy a generated file into place and set its mode.
install_generated() {
    local generated="$1"
    local destination="$2"
    local mode="$3"

    cp "$generated" "$destination"
    chmod "$mode" "$destination"
}

require_modules "${UNIX_MODULES[@]}" "${WINDOWS_MODULES[@]}"

build_unix "$TEMP_DIR/coderun"
build_windows "$TEMP_DIR/coderun.ps1"
validate_powershell "$TEMP_DIR/coderun.ps1"

if [ "$MODE" = "check" ]; then
    status=0

    compare_file "$TEMP_DIR/coderun" "bin/coderun" || status=1
    compare_file "$TEMP_DIR/coderun" "bin/coderun-mac" || status=1
    compare_file "$TEMP_DIR/coderun.ps1" "windows/coderun.ps1" || status=1

    if [ "$status" -ne 0 ]; then
        echo "Generated runners are stale. Run ./scripts/build.sh and commit the result." >&2
        exit 1
    fi

    echo "Generated runners are up to date."
    exit 0
fi

install_generated "$TEMP_DIR/coderun" "bin/coderun" 755
cp -p "bin/coderun" "bin/coderun-mac"
chmod 755 "bin/coderun-mac"
install_generated "$TEMP_DIR/coderun.ps1" "windows/coderun.ps1" 755

echo "Built bin/coderun, bin/coderun-mac, and windows/coderun.ps1."
