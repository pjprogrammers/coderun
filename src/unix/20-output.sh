# shellcheck shell=bash
# =============================================================================
# 20-output.sh - Logging and timing helpers
#
# Small, dependency-free helpers shared by the command, compile, and run
# modules. Keeping them here avoids duplicating formatting logic.
# =============================================================================

# Print an informational message unless --quiet was requested.
log_info() {
    if [ "$QUIET" -eq 0 ]; then
        echo "$@"
    fi
}

# Lowercase a string. Used for case-insensitive extensions and language names.
lowercase() {
    printf '%s' "$1" | tr '[:upper:]' '[:lower:]'
}

# Print the current time in milliseconds.
#
# Uses the first available high-resolution clock. The final fallback only has
# second precision, but it keeps --time working on minimal systems.
now_ms() {
    local value

    if value="$(date +%s%N 2>/dev/null)" && [[ "$value" =~ ^[0-9]+$ ]]; then
        printf '%s\n' "$((value / 1000000))"
        return
    fi

    if command -v perl >/dev/null 2>&1; then
        perl -MTime::HiRes=time -e 'printf "%.0f\n", time * 1000'
        return
    fi

    if command -v python3 >/dev/null 2>&1; then
        python3 -c 'import time; print(int(time.time() * 1000))'
        return
    fi

    printf '%s000\n' "$(date +%s)"
}

# Print elapsed milliseconds in seconds with three decimal places.
# Timing output goes to stderr so it never mixes with program output.
report_elapsed() {
    local start="$1"
    local end
    local elapsed

    end="$(now_ms)"
    elapsed=$((end - start))

    if [ "$elapsed" -lt 0 ]; then
        elapsed=0
    fi

    printf 'coderun: %d.%03ds\n' "$((elapsed / 1000))" "$((elapsed % 1000))" >&2
}
