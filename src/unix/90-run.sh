# shellcheck shell=bash
# shellcheck disable=SC2154
# =============================================================================
# 90-run.sh - Program execution dispatch
#
# Interpreted languages call their interpreter directly. Compiled languages
# either compile and run an artifact, or use a tool that compiles and runs in
# one step (go run, swift, zig run, nim r, crystal run).
# =============================================================================

# Run JavaScript with the selected runtime. Defaults to node.
run_javascript() {
    local runtime="${runtime_opt:-node}"

    case "$runtime" in
        node)
            node "$file" "$@"
            ;;
        bun)
            bun run "$file" "$@"
            ;;
        deno)
            deno run "$file" "$@"
            ;;
    esac
}

# Run TypeScript with the selected runtime. Defaults to tsx.
run_typescript() {
    local runtime="${runtime_opt:-tsx}"

    case "$runtime" in
        node)
            node "$file" "$@"
            ;;
        bun)
            bun run "$file" "$@"
            ;;
        deno)
            deno run "$file" "$@"
            ;;
        tsx)
            tsx "$file" "$@"
            ;;
    esac
}

# Run a compiled language.
#
# With -o/--output we must compile first, then execute the requested artifact.
# Without it, languages with a combined compile-and-run command use that
# command; the rest compile to the default artifact and execute it.
run_compiled() {
    local target

    if [ -n "$output_opt" ]; then
        compile_file || return $?

        if [ "$LANG_ID" = "kotlin" ]; then
            java -jar "$COMPILE_OUTPUT" "$@"
            return $?
        fi

        target="$(resolve_output_path "$COMPILE_OUTPUT")"
        "$target" "$@"
        return $?
    fi

    case "$LANG_ID" in
        c|cpp|rust|fortran|pascal)
            compile_file || return $?
            target="$(resolve_output_path "$COMPILE_OUTPUT")"
            "$target" "$@"
            return $?
            ;;
        kotlin)
            compile_file || return $?
            java -jar "$COMPILE_OUTPUT" "$@"
            return $?
            ;;
        go)
            go run "$file" "$@"
            return $?
            ;;
        swift)
            swift "$file" "$@"
            return $?
            ;;
        zig)
            zig run "$file" -- "$@"
            return $?
            ;;
        nim)
            nim r "$file" -- "$@"
            return $?
            ;;
        crystal)
            crystal run "$file" -- "$@"
            return $?
            ;;
    esac

    return 1
}

# Run any supported source file. Program arguments are passed through
# unchanged.
run_file() {
    case "$LANG_ID" in
        python)
            python3 "$file" "$@"
            return $?
            ;;
        r)
            Rscript "$file" "$@"
            return $?
            ;;
        javascript)
            run_javascript "$@"
            return $?
            ;;
        typescript)
            run_typescript "$@"
            return $?
            ;;
        php)
            php "$file" "$@"
            return $?
            ;;
        ruby)
            ruby "$file" "$@"
            return $?
            ;;
        bash)
            bash "$file" "$@"
            return $?
            ;;
        lua)
            lua "$file" "$@"
            return $?
            ;;
        perl)
            perl "$file" "$@"
            return $?
            ;;
        julia)
            julia "$file" "$@"
            return $?
            ;;
        dart)
            dart run "$file" "$@"
            return $?
            ;;
        elixir)
            elixir "$file" "$@"
            return $?
            ;;
        csharp)
            if [ $# -gt 0 ]; then
                dotnet run "$file" -- "$@"
            else
                dotnet run "$file"
            fi
            return $?
            ;;
        fsharp)
            dotnet fsi "$file" "$@"
            return $?
            ;;
        java)
            java "$file" "$@"
            return $?
            ;;
        c|cpp|rust|go|swift|kotlin|zig|nim|fortran|pascal|crystal)
            run_compiled "$@"
            return $?
            ;;
    esac

    return 1
}
