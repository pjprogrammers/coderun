#!/usr/bin/env bash

set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUNNER="$ROOT/bin/coderun"
CURRENT_VERSION="$(cat "$ROOT/VERSION")"
BASH_BIN="/bin/bash"
HOST_OS="${CODERUN_TEST_OS:-$(uname -s 2>/dev/null || echo unknown)}"

if [ "$HOST_OS" = "Darwin" ]; then
    C_TOOL="clang"
    CPP_TOOL="clang++"
else
    C_TOOL="gcc"
    CPP_TOOL="g++"
fi
TMP="${TMPDIR:-/tmp}/coderun-tests.$$"
FAKE_BIN="$TMP/fake-bin"
SAFE_BIN="$TMP/safe-bin"
SHIM_LOG="$TMP/shims.log"
PASS=0
FAIL=0

cleanup() {
    rm -rf "$TMP"
}
trap cleanup EXIT

rm -rf "$TMP"
mkdir -p "$FAKE_BIN" "$SAFE_BIN" "$TMP/work"
: > "$SHIM_LOG"

for command in awk basename cat chmod cp date dirname grep head ls mkdir mv perl rm sed touch tr uname; do
    found="$(command -v "$command" 2>/dev/null || true)"
    if [ -n "$found" ]; then
        ln -s "$found" "$SAFE_BIN/$command"
    fi
done

for tool in gcc g++ clang clang++ python3 Rscript java javac rustc node tsx go php ruby bash swift swiftc kotlinc lua perl julia dart elixir zig nim gfortran fpc crystal dotnet bun deno; do
    ln -s "$ROOT/tests/fake-tool.sh" "$FAKE_BIN/$tool"
done
chmod 755 "$ROOT/tests/fake-tool.sh"

if [ "$HOST_OS" = "Darwin" ]; then
    cat > "$FAKE_BIN/uname" <<'EOF'
#!/bin/bash
printf 'Darwin\n'
EOF
    chmod 755 "$FAKE_BIN/uname"
fi

# shellcheck source=tests/lib/assertions.sh
source "$ROOT/tests/lib/assertions.sh"

run_runner() {
    PATH="$FAKE_BIN:$SAFE_BIN" SHIM_LOG="$SHIM_LOG" HOME="$TMP/home" TMPDIR="$TMP" "$BASH_BIN" "$RUNNER" "$@"
}

last_log() {
    tail -n 1 "$SHIM_LOG"
}

log_contains() {
    grep -qF -- "$1" "$SHIM_LOG"
}

# ---------------------------------------------------------------------------
# Version, help, list, check
# ---------------------------------------------------------------------------

output="$(run_runner --version)"
assert_eq "version" "coderun $CURRENT_VERSION" "$output"

output="$(run_runner --help)"
assert_contains "help shows argument forwarding" "program args" "$output"
assert_contains "help shows runtime" "--runtime" "$output"
assert_contains "help shows F#" "F#" "$output"

output="$(run_runner --list)"
assert_contains "list includes new languages" "C#" "$output"
assert_eq "list has 26 language rows" "26" "$(printf '%s\n' "$output" | grep -cE '^  [A-Za-z+#]+ +\.')"

output="$(run_runner --list --verbose)"
assert_contains "verbose list reports installed tools" "installed" "$output"
assert_not_contains "verbose list has no missing tools" "missing:" "$output"

output="$(run_runner --check --strict)"
code=$?
assert_eq "strict check with all shims" "0" "$code"
assert_contains "strict check summary" "26 of 26 language toolchains" "$output"

rm -f "$FAKE_BIN/zig"
output="$(run_runner --check)"
code=$?
assert_eq "default check exits 0 when tools are missing" "0" "$code"
assert_contains "default check reports missing language" "Zig" "$output"
assert_contains "default check reports missing tool" "missing: zig" "$output"

output="$(run_runner --check zig)"
code=$?
assert_eq "targeted check exits 1 when missing" "1" "$code"
assert_contains "targeted check names the tool" "Zig: missing: zig" "$output"

output="$(run_runner --check --strict)"
code=$?
assert_eq "strict check exits 1 when missing" "1" "$code"

ln -s "$ROOT/tests/fake-tool.sh" "$FAKE_BIN/zig"
output="$(run_runner --check zig)"
code=$?
assert_eq "targeted check exits 0 when present" "0" "$code"

output="$(run_runner --check not-a-language)"
code=$?
assert_eq "unknown check target exits 1" "1" "$code"
assert_contains "unknown check target message" "Unknown language" "$output"

# ---------------------------------------------------------------------------
# Argument forwarding
# ---------------------------------------------------------------------------

printf 'print("hello")\n' > "$TMP/work/args.py"
output="$(run_runner "$TMP/work/args.py" --verbose "a b" -- --flag)"
assert_contains "python receives program arguments" "python3|$TMP/work/args.py|--verbose|a b|--|--flag" "$(last_log)"
assert_not_contains "program arguments are not parsed as coderun options" "Supported languages" "$output"

output="$(run_runner "$TMP/work/args.py" -- --only)"
assert_contains "one -- separator after the file is dropped" "python3|$TMP/work/args.py|--only" "$(last_log)"

output="$(run_runner "$TMP/work/args.py" --list)"
assert_not_contains "forwarded --list does not list languages" "Supported languages" "$output"

output="$(SHIM_EXIT=42 run_runner "$TMP/work/args.py")"
code=$?
assert_eq "program exit code is preserved" "42" "$code"

output="$(run_runner --time "$TMP/work/args.py" x 2>&1)"
code=$?
assert_eq "time preserves exit code" "0" "$code"
assert_contains "time reports elapsed" "coderun: " "$output"

# ---------------------------------------------------------------------------
# Compiled languages, output, clean, compile errors
# ---------------------------------------------------------------------------

printf 'int main(void) { return 0; }\n' > "$TMP/work/main.c"
output="$(run_runner "$TMP/work/main.c" alpha "b c")"
assert_contains "C compiles" "$C_TOOL|$TMP/work/main.c|-o|$TMP/work/main" "$(grep "^$C_TOOL" "$SHIM_LOG" | tail -n 1)"
assert_contains "compiled program receives arguments" "RUN:$C_TOOL|alpha|b c" "$output"

output="$(run_runner --compile "$TMP/work/main.c")"
code=$?
assert_eq "compile-only exits 0" "0" "$code"
assert_contains "compile-only reports artifact" "Compiled $TMP/work/main.c" "$output"
[ -x "$TMP/work/main" ] && ok "compiled artifact exists and is executable" || bad "compiled artifact exists and is executable"

output="$(run_runner --quiet --compile "$TMP/work/main.c")"
assert_eq "quiet compile suppresses coderun output" "" "$output"

output="$(run_runner --clean "$TMP/work/main.c")"
code=$?
assert_eq "clean exits 0" "0" "$code"
[ ! -e "$TMP/work/main" ] && ok "clean removes artifact" || bad "clean removes artifact"

output="$(run_runner -o "$TMP/work/app" "$TMP/work/main.c" --port 9)"
assert_contains "custom output compiles to requested path" "$C_TOOL|$TMP/work/main.c|-o|$TMP/work/app" "$(grep "^$C_TOOL" "$SHIM_LOG" | tail -n 1)"
assert_contains "custom output artifact receives arguments" "RUN:$C_TOOL|--port|9" "$output"

output="$(run_runner --compile "$TMP/work/main.c" extra)"
code=$?
assert_eq "compile rejects program arguments" "1" "$code"

output="$(run_runner --clean "$TMP/work/main.c" extra)"
code=$?
assert_eq "clean rejects program arguments" "1" "$code"

output="$(run_runner --unknown "$TMP/work/main.c")"
code=$?
assert_eq "unknown option before file exits 1" "1" "$code"

printf 'print("dash")\n' > "$TMP/work/-dash.py"
output="$(cd "$TMP/work" && PATH="$FAKE_BIN:$SAFE_BIN" SHIM_LOG="$SHIM_LOG" HOME="$TMP/home" TMPDIR="$TMP" "$BASH_BIN" "$RUNNER" -- -dash.py --ok)"
code=$?
assert_eq "filename starting with dash works after --" "0" "$code"
assert_contains "dash filename receives arguments" "python3|-dash.py|--ok" "$(last_log)"

# ---------------------------------------------------------------------------
# JavaScript and TypeScript runtimes
# ---------------------------------------------------------------------------

printf 'console.log("js")\n' > "$TMP/work/app.js"
printf 'console.log("ts")\n' > "$TMP/work/app.ts"

output="$(run_runner --runtime bun "$TMP/work/app.js" arg)"
assert_contains "JavaScript with bun" "bun|run|$TMP/work/app.js|arg" "$(last_log)"

output="$(run_runner --runtime node "$TMP/work/app.ts" arg)"
assert_contains "TypeScript with node" "node|$TMP/work/app.ts|arg" "$(last_log)"

output="$(run_runner --runtime deno "$TMP/work/app.ts" arg)"
assert_contains "TypeScript with deno" "deno|run|$TMP/work/app.ts|arg" "$(last_log)"

output="$(run_runner --runtime bun "$TMP/work/args.py")"
code=$?
assert_eq "runtime rejects non-JS/TS" "1" "$code"

output="$(run_runner --runtime nope "$TMP/work/app.js")"
code=$?
assert_eq "runtime validates names" "1" "$code"

# ---------------------------------------------------------------------------
# Every language dispatches to the expected tool
# ---------------------------------------------------------------------------

dispatch_cases=(
    "py|python3||args.py"
    "r|Rscript||args.R"
    "js|node||app.js"
    "ts|tsx||app.ts"
    "php|php||app.php"
    "rb|ruby||app.rb"
    "sh|bash||app.sh"
    "lua|lua||app.lua"
    "pl|perl||app.pl"
    "jl|julia||app.jl"
    "dart|dart|run|app.dart"
    "exs|elixir||app.exs"
    "cs|dotnet|run|app.cs"
    "fsx|dotnet|fsi|app.fsx"
    "java|java||App.java"
    "c|$C_TOOL||main.c"
    "cpp|$CPP_TOOL||main.cpp"
    "rs|rustc||main.rs"
    "go|go|run|main.go"
    "swift|swift||main.swift"
    "kt|kotlinc||Main.kt"
    "zig|zig|run|main.zig"
    "nim|nim|r|main.nim"
    "f90|gfortran||main.f90"
    "pas|fpc||main.pas"
    "cr|crystal|run|main.cr"
)

for case in "${dispatch_cases[@]}"; do
    IFS='|' read -r extension tool subcommand sample <<< "$case"
    file="$TMP/work/$extension-$sample"
    printf 'sample\n' > "$file"
    : > "$SHIM_LOG"

    output="$(run_runner "$file" passed-arg)"
    if [ -n "$subcommand" ]; then
        expected="$tool|$subcommand|"
    else
        expected="$tool|"
    fi

    if log_contains "$expected"; then
        ok "dispatch .$extension -> $tool${subcommand:+ $subcommand}"
    else
        bad "dispatch .$extension -> $tool${subcommand:+ $subcommand}" "log: $(cat "$SHIM_LOG")
output: $output"
    fi
done

# ---------------------------------------------------------------------------
# Completions
# ---------------------------------------------------------------------------

for shell in bash zsh fish powershell; do
    output="$(run_runner --completions "$shell")"
    code=$?
    assert_eq "completions $shell exits 0" "0" "$code"
    assert_contains "completions $shell has coderun" "coderun" "$output"
done

output="$(run_runner --completions nope)"
code=$?
assert_eq "unknown completion shell exits 1" "1" "$code"

# ---------------------------------------------------------------------------
# Usage errors
# ---------------------------------------------------------------------------

output="$(run_runner --compile)"
code=$?
assert_eq "compile without file exits 1" "1" "$code"

output="$(run_runner --clean)"
code=$?
assert_eq "clean without file exits 1" "1" "$code"

output="$(run_runner "$TMP/work/missing.py")"
code=$?
assert_eq "missing file exits 1" "1" "$code"

printf 'x\n' > "$TMP/work/file.xyz"
output="$(run_runner "$TMP/work/file.xyz")"
code=$?
assert_eq "unsupported extension exits 1" "1" "$code"

output="$(run_runner --compile --clean "$TMP/work/main.c")"
code=$?
assert_eq "compile and clean conflict exits 1" "1" "$code"

output="$(run_runner -o out "$TMP/work/args.py")"
code=$?
assert_eq "output rejects interpreted languages" "1" "$code"

output="$(run_runner --list file.py)"
code=$?
assert_eq "list rejects extra arguments" "1" "$code"

echo
echo "Passed: $PASS  Failed: $FAIL"
[ "$FAIL" -eq 0 ]
