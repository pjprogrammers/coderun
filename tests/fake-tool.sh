#!/bin/bash

# Shared fake tool used by tests. Every runtime and compiler is a symlink to
# this script, so tests can verify dispatch and argument forwarding without
# installing 26 toolchains.

tool="${0##*/}"

if [ -n "${SHIM_LOG:-}" ]; then
    {
        printf '%s' "$tool"
        for argument in "$@"; do
            printf '|%s' "$argument"
        done
        printf '\n'
    } >> "$SHIM_LOG"
fi

create_executable() {
    local output="$1"
    local label="$2"

    if [ -z "$output" ]; then
        return 0
    fi

    mkdir -p "$(dirname "$output")"
    cat > "$output" <<EOF
#!/bin/bash
printf 'RUN:$label'
for argument in "\$@"; do
    printf '|%s' "\$argument"
done
printf '\n'
exit \${SHIM_PROGRAM_EXIT:-0}
EOF
    chmod 755 "$output"
}

find_output_after() {
    local flag="$1"
    shift
    local previous=""
    local argument

    for argument in "$@"; do
        if [ "$previous" = "$flag" ]; then
            printf '%s' "$argument"
            return 0
        fi
        previous="$argument"
    done

    return 1
}

output=""

case "$tool" in
    gcc|g++|clang|clang++|rustc|gfortran|swiftc)
        output="$(find_output_after "-o" "$@")"
        create_executable "$output" "$tool"
        ;;
    fpc)
        for argument in "$@"; do
            case "$argument" in
                -o*) output="${argument#-o}" ;;
            esac
        done
        create_executable "$output" "$tool"
        ;;
    zig)
        if [ "${1:-}" = "build-exe" ]; then
            for argument in "$@"; do
                case "$argument" in
                    -femit-bin=*) output="${argument#-femit-bin=}" ;;
                esac
            done
            create_executable "$output" "zig"
        fi
        ;;
    nim)
        if [ "${1:-}" = "c" ]; then
            for argument in "$@"; do
                case "$argument" in
                    --out:*) output="${argument#--out:}" ;;
                esac
            done
            create_executable "$output" "nim"
        fi
        ;;
    crystal)
        if [ "${1:-}" = "build" ]; then
            output="$(find_output_after "-o" "$@")"
            create_executable "$output" "crystal"
        fi
        ;;
    go)
        if [ "${1:-}" = "build" ]; then
            output="$(find_output_after "-o" "$@")"
            create_executable "$output" "go"
        fi
        ;;
    kotlinc)
        output="$(find_output_after "-d" "$@")"
        if [ -n "$output" ]; then
            mkdir -p "$(dirname "$output")"
            : > "$output"
        fi
        ;;
    javac)
        ;;
esac

if [ -n "${SHIM_EXIT:-}" ]; then
    exit "$SHIM_EXIT"
fi

exit 0
