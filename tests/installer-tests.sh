#!/usr/bin/env bash

set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BASH_BIN="$(command -v bash)"
TMP="${TMPDIR:-/tmp}/coderun-installer-tests.$$"
SAFE_BIN="$TMP/safe-bin"
PASS=0
FAIL=0

cleanup() {
    rm -rf "$TMP"
}
trap cleanup EXIT

rm -rf "$TMP"
mkdir -p "$SAFE_BIN"

for command in cp chmod cmp dirname grep mkdir touch; do
    found="$(command -v "$command" 2>/dev/null || true)"
    if [ -n "$found" ]; then
        ln -s "$found" "$SAFE_BIN/$command"
    fi
done

ok() {
    echo "PASS: $1"
    PASS=$((PASS + 1))
}

bad() {
    echo "FAIL: $1"
    if [ $# -gt 1 ]; then
        printf '%s\n' "$2"
    fi
    FAIL=$((FAIL + 1))
}

assert_eq() {
    local name="$1"
    local expected="$2"
    local actual="$3"

    if [ "$expected" = "$actual" ]; then
        ok "$name"
    else
        bad "$name" "expected: <$expected>
actual:   <$actual>"
    fi
}

assert_contains() {
    local name="$1"
    local needle="$2"
    local haystack="$3"

    if printf '%s' "$haystack" | grep -qF -- "$needle"; then
        ok "$name"
    else
        bad "$name" "missing: <$needle>
output:
$haystack"
    fi
}

assert_not_contains() {
    local name="$1"
    local needle="$2"
    local haystack="$3"

    if printf '%s' "$haystack" | grep -qF -- "$needle"; then
        bad "$name" "unexpected: <$needle>
output:
$haystack"
    else
        ok "$name"
    fi
}

make_fake_tools() {
    local directory="$1"
    shift

    mkdir -p "$directory"
    for tool in "$@"; do
        : > "$directory/$tool"
        chmod 755 "$directory/$tool"
    done
}

run_installer() {
    local installer="$1"
    local home="$2"
    local path_prefix="$3"

    HOME="$home" PATH="${path_prefix:+$path_prefix:}$SAFE_BIN" \
        "$BASH_BIN" "$installer"
}

# ---------------------------------------------------------------------------
# Linux installer without language toolchains
# ---------------------------------------------------------------------------

linux_home="$TMP/linux-home"
linux_output="$(run_installer "$ROOT/install.sh" "$linux_home" "")"
linux_status=$?

assert_eq "Linux install succeeds without gcc/g++/python3" "0" "$linux_status"
assert_contains "Linux install warns about gcc" "warning: gcc was not found." "$linux_output"
assert_contains "Linux install warns about g++" "warning: g++ was not found." "$linux_output"
assert_contains "Linux install warns about python3" "warning: python3 was not found." "$linux_output"
assert_contains "Linux install confirms success" "coderun installed successfully!" "$linux_output"
assert_not_contains "Linux install does not report an error" "Error:" "$linux_output"
[ -x "$linux_home/.local/bin/coderun" ] && ok "Linux installed runner is executable" || bad "Linux installed runner is executable"
cmp -s "$ROOT/bin/coderun" "$linux_home/.local/bin/coderun" && ok "Linux installed runner matches bin/coderun" || bad "Linux installed runner matches bin/coderun"
assert_eq "Linux installer adds PATH once" "1" "$(grep -cF 'export PATH="$HOME/.local/bin:$PATH"' "$linux_home/.bashrc" 2>/dev/null || true)"

linux_output="$(run_installer "$ROOT/install.sh" "$linux_home" "")"
linux_status=$?
assert_eq "Linux reinstall succeeds" "0" "$linux_status"
assert_contains "Linux reinstall reports upgrade" "Existing installation found - upgrading..." "$linux_output"
assert_eq "Linux reinstall keeps one PATH entry" "1" "$(grep -cF 'export PATH="$HOME/.local/bin:$PATH"' "$linux_home/.bashrc" 2>/dev/null || true)"

linux_tools="$TMP/linux-tools"
make_fake_tools "$linux_tools" gcc g++ python3
linux_spaced_home="$TMP/linux home with spaces"
linux_output="$(run_installer "$ROOT/install.sh" "$linux_spaced_home" "$linux_tools" 2>&1)"
linux_status=$?
assert_eq "Linux install succeeds with tools in a home path containing spaces" "0" "$linux_status"
assert_not_contains "Linux install has no warnings when tools exist" "warning:" "$linux_output"
[ -x "$linux_spaced_home/.local/bin/coderun" ] && ok "Spaced HOME install is executable" || bad "Spaced HOME install is executable"

# ---------------------------------------------------------------------------
# macOS installer without language toolchains
# ---------------------------------------------------------------------------

mac_home="$TMP/mac-home"
mac_output="$(run_installer "$ROOT/install-mac.sh" "$mac_home" "")"
mac_status=$?

assert_eq "macOS install succeeds without clang/python3" "0" "$mac_status"
assert_contains "macOS install warns about clang" "warning: clang was not found." "$mac_output"
assert_contains "macOS install warns about clang++" "warning: clang++ was not found." "$mac_output"
assert_contains "macOS install warns about python3" "warning: python3 was not found." "$mac_output"
assert_contains "macOS install confirms success" "coderun installed successfully!" "$mac_output"
assert_not_contains "macOS install does not report an error" "Error:" "$mac_output"
[ -x "$mac_home/.local/bin/coderun" ] && ok "macOS installed runner is executable" || bad "macOS installed runner is executable"
cmp -s "$ROOT/bin/coderun-mac" "$mac_home/.local/bin/coderun" && ok "macOS installed runner matches bin/coderun-mac" || bad "macOS installed runner matches bin/coderun-mac"
[ -f "$mac_home/.zprofile" ] && ok "macOS installer creates .zprofile" || bad "macOS installer creates .zprofile"
assert_eq "macOS installer adds PATH once" "1" "$(grep -cF 'export PATH="$HOME/.local/bin:$PATH"' "$mac_home/.zprofile" 2>/dev/null || true)"

mac_tools="$TMP/mac-tools"
make_fake_tools "$mac_tools" clang clang++ python3
mac_home_zsh="$TMP/mac-home-zsh"
mkdir -p "$mac_home_zsh"
: > "$mac_home_zsh/.zshrc"
mac_output="$(run_installer "$ROOT/install-mac.sh" "$mac_home_zsh" "$mac_tools" 2>&1)"
mac_status=$?
assert_eq "macOS install succeeds with tools and existing .zshrc" "0" "$mac_status"
assert_not_contains "macOS install has no warnings when tools exist" "warning:" "$mac_output"
assert_eq "macOS installer adds PATH to .zshrc" "1" "$(grep -cF 'export PATH="$HOME/.local/bin:$PATH"' "$mac_home_zsh/.zshrc" 2>/dev/null || true)"
[ ! -e "$mac_home_zsh/.zprofile" ] && ok "macOS installer prefers .zshrc over .zprofile" || bad "macOS installer prefers .zshrc over .zprofile"

echo
echo "Passed: $PASS  Failed: $FAIL"
[ "$FAIL" -eq 0 ]
