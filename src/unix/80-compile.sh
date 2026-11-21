# shellcheck shell=bash
# shellcheck disable=SC2154
# =============================================================================
# 80-compile.sh - Artifact naming, compilation, and cleanup
#
# The compile module owns everything that produces or removes files on disk.
# It relies on the LANG_* variables set by resolve_extension and on the
# source-path variables set by the CLI module:
#   file, dir, name, base, ext, output_opt, COMPILE_OUTPUT
# =============================================================================

# Decide where a compiled artifact should be written.
#
# With -o/--output, the user's path wins. Kotlin gets a .jar suffix when the
# user did not provide one. Without -o, Java writes classes beside the source,
# Kotlin writes <base>.jar, and every other compiled language writes <base>.
compile_artifact() {
    if [ -n "$output_opt" ]; then
        case "$LANG_ID" in
            kotlin)
                case "${output_opt##*/}" in
                    *.*)
                        COMPILE_OUTPUT="$output_opt"
                        ;;
                    *)
                        COMPILE_OUTPUT="$output_opt.jar"
                        ;;
                esac
                ;;
            *)
                COMPILE_OUTPUT="$output_opt"
                ;;
        esac
    else
        case "$LANG_ID" in
            java)
                COMPILE_OUTPUT="$dir"
                ;;
            kotlin)
                COMPILE_OUTPUT="$dir/$base.jar"
                ;;
            *)
                COMPILE_OUTPUT="$dir/$base"
                ;;
        esac
    fi
}

# Turn a possibly relative artifact path into an absolute path.
resolve_output_path() {
    case "$1" in
        /*)
            printf '%s\n' "$1"
            ;;
        *)
            printf '%s/%s\n' "$(pwd)" "$1"
            ;;
    esac
}

# Compile the current source file to COMPILE_OUTPUT.
# Returns the compiler's exit status.
compile_file() {
    compile_artifact

    case "$LANG_ID" in
        cpp)
            "$CPP_COMPILER" "$file" -o "$COMPILE_OUTPUT"
            return $?
            ;;
        c)
            "$C_COMPILER" "$file" -o "$COMPILE_OUTPUT"
            return $?
            ;;
        java)
            javac "$file" -d "$dir"
            return $?
            ;;
        rust)
            rustc "$file" -o "$COMPILE_OUTPUT"
            return $?
            ;;
        go)
            go build -o "$COMPILE_OUTPUT" "$file"
            return $?
            ;;
        swift)
            swiftc "$file" -o "$COMPILE_OUTPUT"
            return $?
            ;;
        kotlin)
            kotlinc "$file" -include-runtime -d "$COMPILE_OUTPUT"
            return $?
            ;;
        zig)
            zig build-exe "$file" -femit-bin="$COMPILE_OUTPUT"
            return $?
            ;;
        nim)
            nim c --out:"$COMPILE_OUTPUT" "$file"
            return $?
            ;;
        fortran)
            gfortran "$file" -o "$COMPILE_OUTPUT"
            return $?
            ;;
        pascal)
            fpc "$file" "-o$COMPILE_OUTPUT"
            return $?
            ;;
        crystal)
            crystal build "$file" -o "$COMPILE_OUTPUT"
            return $?
            ;;
    esac

    return 1
}

# State for clean_file. Reset on every call so the function can be reused.
CLEANED=0
CLEAN_FAILED=0

# Remove one artifact and record the outcome.
remove_artifact() {
    if [ -e "$1" ]; then
        if rm -f "$1"; then
            log_info "Removed $1"
            CLEANED=1
        else
            echo "Error: could not remove $1."
            CLEAN_FAILED=1
        fi
    fi
}

# Remove every artifact that the current language can generate for the source
# file, including custom output paths and Java inner classes.
clean_file() {
    local class_file
    local custom_artifact

    CLEANED=0
    CLEAN_FAILED=0

    if [ "$LANG_TYPE" = "interpreted" ]; then
        log_info "No build artifacts to clean for .$ext files (interpreted language)."
        return 0
    fi

    if [ -n "$output_opt" ]; then
        case "$LANG_ID" in
            kotlin)
                case "${output_opt##*/}" in
                    *.*)
                        custom_artifact="$output_opt"
                        ;;
                    *)
                        custom_artifact="$output_opt.jar"
                        ;;
                esac
                remove_artifact "$custom_artifact"
                ;;
            java)
                # Java has no custom artifact; class files go beside the source.
                ;;
            *)
                remove_artifact "$output_opt"
                ;;
        esac
    fi

    case "$LANG_ID" in
        c|cpp|rust|go|swift|fortran|pascal|crystal)
            remove_artifact "$dir/$base"
            ;;
        kotlin)
            remove_artifact "$dir/$base.jar"
            ;;
        zig)
            remove_artifact "$dir/$base"
            remove_artifact "$dir/$base.o"
            ;;
        nim)
            remove_artifact "$dir/$base"
            ;;
        java)
            remove_artifact "$dir/$base.class"
            for class_file in "$dir/$base"\$*.class; do
                if [ -e "$class_file" ]; then
                    remove_artifact "$class_file"
                fi
            done
            ;;
    esac

    if [ "$CLEANED" -eq 0 ]; then
        log_info "No build artifacts found for $file."
    fi

    if [ "$CLEAN_FAILED" -ne 0 ]; then
        return 1
    fi

    return 0
}
