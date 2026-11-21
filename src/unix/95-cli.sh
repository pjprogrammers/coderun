# shellcheck shell=bash
# shellcheck disable=SC2034
# =============================================================================
# 95-cli.sh - Command-line parsing, validation, and dispatch
#
# This module is the control centre. It keeps a small amount of global state
# because Bash functions cannot return structured values cleanly. The contract
# is:
#
#   Parsing fills:
#     mode, action, output_opt, runtime_opt, check_target, check_strict,
#     list_verbose, time_it, completion_shell, file, program_args
#
#   Validation adds:
#     dir, name, base, ext, LANG_ID, LANG_NAME, LANG_TYPE, LANG_TOOLS
#
#   Execution consumes all of the above and exits with the program or
#     compiler exit code.
# =============================================================================

mode="run"
action=""
output_opt=""
runtime_opt=""
check_target=""
check_strict=0
list_verbose=0
time_it=0
completion_shell=""
file=""
program_args=()

# Select run/compile/clean mode. Compile and clean are mutually exclusive.
set_mode() {
    if [ "$mode" != "run" ] && [ "$mode" != "$1" ]; then
        echo "Error: --compile and --clean cannot be used together."
        exit 1
    fi
    mode="$1"
}

# Select a top-level action. Two different actions cannot be combined.
set_action() {
    if [ -n "$action" ] && [ "$action" != "$1" ]; then
        echo "Error: --$action and --$1 cannot be combined."
        exit 1
    fi
    action="$1"
}

# Parse coderun options until the source file is reached. Everything after the
# source file belongs to the program, except for one optional -- separator.
parse_arguments() {
    while [ $# -gt 0 ]; do
        if [ -n "$file" ]; then
            if [ "${#program_args[@]}" -eq 0 ] && [ "$1" = "--" ]; then
                shift
            fi
            if [ $# -gt 0 ]; then
                program_args=("$@")
            fi
            break
        fi

        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--version)
                echo "coderun $CODERUN_VERSION"
                exit 0
                ;;
            --list)
                set_action "list"
                ;;
            --verbose)
                list_verbose=1
                ;;
            --check)
                set_action "check"
                ;;
            --strict)
                check_strict=1
                ;;
            --info)
                set_action "info"
                ;;
            --check-update)
                set_action "check-update"
                ;;
            --update)
                set_action "update"
                ;;
            --uninstall)
                set_action "uninstall"
                ;;
            --completions)
                if [ $# -lt 2 ] || [ -z "$2" ]; then
                    echo "Error: --completions requires a shell name."
                    exit 1
                fi
                set_action "completions"
                completion_shell="$2"
                shift
                ;;
            --compile)
                set_mode "compile"
                ;;
            --clean)
                set_mode "clean"
                ;;
            -o|--output)
                if [ $# -lt 2 ] || [ -z "$2" ]; then
                    echo "Error: $1 requires an output path."
                    exit 1
                fi
                output_opt="$2"
                shift
                ;;
            --runtime)
                if [ $# -lt 2 ] || [ -z "$2" ]; then
                    echo "Error: --runtime requires a value: node, bun, or deno."
                    exit 1
                fi
                runtime_opt="$2"
                shift
                ;;
            --time)
                time_it=1
                ;;
            -q|--quiet)
                QUIET=1
                ;;
            --)
                shift
                if [ $# -gt 0 ]; then
                    file="$1"
                    shift
                fi
                if [ $# -gt 0 ]; then
                    program_args=("$@")
                fi
                break
                ;;
            -*)
                echo "Unknown option: $1"
                echo "Try 'coderun --help' for more information."
                exit 1
                ;;
            *)
                if [ "$action" = "check" ] && [ -z "$check_target" ]; then
                    check_target="$1"
                else
                    file="$1"
                fi
                ;;
        esac

        shift
    done
}

# Handle a top-level action (--list, --check, --info, etc.).
# Returns immediately when no action was requested; otherwise it exits.
handle_action() {
    if [ -z "$action" ]; then
        return 0
    fi

    if [ "$mode" != "run" ]; then
        echo "Error: --$action cannot be combined with --compile or --clean."
        exit 1
    fi

    if [ -n "$output_opt" ]; then
        echo "Error: --$action cannot be combined with -o/--output."
        exit 1
    fi

    if [ "$action" != "check" ] && [ "$action" != "list" ] && [ -n "$file" ]; then
        echo "Error: unexpected argument: $file"
        exit 1
    fi

    case "$action" in
        list)
            if [ -n "$file" ] || [ -n "$check_target" ]; then
                echo "Error: unexpected argument: ${file:-$check_target}"
                exit 1
            fi
            show_languages "$list_verbose"
            exit 0
            ;;
        check)
            if [ -n "$file" ]; then
                echo "Error: unexpected argument: $file"
                exit 1
            fi
            check_dependencies "$check_target" "$check_strict"
            exit $?
            ;;
        info)
            show_info
            exit 0
            ;;
        check-update)
            check_update
            exit $?
            ;;
        update)
            update_coderun
            exit 0
            ;;
        uninstall)
            uninstall_coderun
            exit 0
            ;;
        completions)
            show_completions "$completion_shell"
            exit $?
            ;;
    esac
}

# Split the source path into directory, filename, base name, and extension.
resolve_source_path() {
    dir="."
    name="$file"

    case "$file" in
        */*)
            dir="${file%/*}"
            name="${file##*/}"
            if [ -z "$dir" ]; then
                dir="/"
            fi
            ;;
    esac

    base="${name%.*}"
    ext="${name##*.}"
    ext="$(lowercase "$ext")"
}

# Validate --runtime and store a normalized value.
validate_runtime() {
    if [ -z "$runtime_opt" ]; then
        return 0
    fi

    case "$runtime_opt" in
        node|bun|deno)
            ;;
        *)
            echo "Error: unknown runtime: $runtime_opt"
            echo "Supported runtimes: node, bun, deno."
            exit 1
            ;;
    esac

    case "$LANG_ID" in
        javascript|typescript)
            ;;
        *)
            echo "Error: --runtime is only supported for JavaScript and TypeScript."
            exit 1
            ;;
    esac
}

# Validate -o/--output against the selected language.
validate_output() {
    if [ -z "$output_opt" ]; then
        return 0
    fi

    case "$LANG_ID" in
        java)
            echo "Error: -o/--output is not supported for Java."
            exit 1
            ;;
    esac

    if [ "$LANG_TYPE" != "compiled" ]; then
        echo "Error: -o/--output is only supported for compiled languages."
        exit 1
    fi

    if [ "$output_opt" = "$file" ]; then
        echo "Error: output path must not be the source file."
        exit 1
    fi
}

# Validate flag combinations, the source file, and language-specific options.
validate_invocation() {
    if [ "$list_verbose" -eq 1 ]; then
        echo "Error: --verbose can only be used with --list."
        exit 1
    fi

    if [ "$check_strict" -eq 1 ]; then
        echo "Error: --strict can only be used with --check."
        exit 1
    fi

    if [ "$mode" = "compile" ] || [ "$mode" = "clean" ]; then
        if [ -z "$file" ]; then
            echo "Error: --$mode requires a source file."
            exit 1
        fi
    fi

    if [ -z "$file" ]; then
        if [ -n "$output_opt" ]; then
            echo "Error: -o/--output requires a source file."
            exit 1
        fi

        show_help
        exit 1
    fi

    if [ ! -f "$file" ]; then
        echo "Error: file not found: $file"
        exit 1
    fi

    resolve_source_path

    if ! resolve_extension "$ext"; then
        echo "Unsupported file type: .$ext"
        echo "Run 'coderun --list' to see supported languages."
        exit 1
    fi

    validate_runtime
    validate_output
}

# Compile-only mode. Reports the artifact and exits with the compiler status.
execute_compile() {
    local start_time=0
    local status

    if [ "${#program_args[@]}" -gt 0 ]; then
        echo "Error: --compile does not accept program arguments."
        exit 1
    fi

    if [ "$LANG_TYPE" != "compiled" ]; then
        echo "Error: cannot compile .$ext files; this language is interpreted."
        echo "Use 'coderun \"$file\"' to run it directly."
        exit 1
    fi

    if [ "$time_it" -eq 1 ]; then
        start_time="$(now_ms)"
    fi

    compile_file
    status=$?

    if [ "$status" -ne 0 ]; then
        exit "$status"
    fi

    if [ "$time_it" -eq 1 ]; then
        report_elapsed "$start_time"
    fi

    if [ "$LANG_ID" = "java" ]; then
        log_info "Compiled $file -> $dir (Java class files)"
    else
        log_info "Compiled $file -> $COMPILE_OUTPUT"
    fi

    exit 0
}

# Run mode. Times the program when requested and preserves its exit code.
execute_run() {
    local start_time=0
    local status

    if [ "$time_it" -eq 1 ]; then
        start_time="$(now_ms)"
    fi

    run_file "${program_args[@]}"
    status=$?

    if [ "$time_it" -eq 1 ]; then
        report_elapsed "$start_time"
    fi

    exit "$status"
}

# Dispatch to clean, compile, or run.
execute() {
    local status

    if [ "$mode" = "clean" ]; then
        if [ "${#program_args[@]}" -gt 0 ]; then
            echo "Error: --clean does not accept program arguments."
            exit 1
        fi

        clean_file
        status=$?
        exit "$status"
    fi

    if [ "$mode" = "compile" ]; then
        execute_compile
    fi

    execute_run
}

# Entry point for the generated runner.
main() {
    parse_arguments "$@"
    handle_action
    validate_invocation
    execute
}
