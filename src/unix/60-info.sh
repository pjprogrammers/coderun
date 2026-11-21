# shellcheck shell=bash
# =============================================================================
# 60-info.sh - --info support
#
# Resolves the path of the running script (following symlinks) and prints the
# environment details users need when reporting a problem.
# =============================================================================

# Print the canonical path of this script, even when it was invoked through a
# symlink or found on PATH without a slash.
resolve_script_path() {
    local source="${BASH_SOURCE[0]}"
    local dir

    case "$source" in
        */*) ;;
        *)
            source="$(command -v -- "$source" 2>/dev/null || printf '%s' "$source")"
            ;;
    esac

    while [ -L "$source" ]; do
        dir="$(cd -P "$(dirname "$source")" >/dev/null 2>&1 && pwd)"
        source="$(readlink "$source")"
        case "$source" in
            /*) ;;
            *) source="$dir/$source" ;;
        esac
    done

    dir="$(cd -P "$(dirname "$source")" >/dev/null 2>&1 && pwd)"
    printf '%s/%s\n' "$dir" "$(basename "$source")"
}

show_info() {
    local script_path
    local os_name
    local arch

    script_path="$(resolve_script_path)"
    os_name="$(uname -s 2>/dev/null || echo unknown)"
    arch="$(uname -m 2>/dev/null || echo unknown)"

    echo "coderun $CODERUN_VERSION"
    echo "Install path: $script_path"
    echo "Operating system: $os_name"
    echo "Architecture: $arch"
    echo "Shell: ${SHELL:-unknown}"
    echo "Languages: $LANGUAGE_COUNT"
    echo "Runner URL: $CODERUN_RAW_BASE/v$CODERUN_VERSION/$RUNNER_PATH"
}
