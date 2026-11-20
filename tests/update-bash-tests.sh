#!/usr/bin/env bash

set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUNNER="$ROOT/bin/coderun"
PYTHON="$(command -v python3 || true)"
TMP="${TMPDIR:-/tmp}/coderun-update-tests.$$"
SERVE="$TMP/serve"
HOME_DIR="$TMP/home"
PORT=$((19000 + ($$ % 500)))
BASE_URL="http://127.0.0.1:$PORT"
PASS=0
FAIL=0
SERVER_PID=""

cleanup() {
    if [ -n "$SERVER_PID" ]; then
        kill "$SERVER_PID" 2>/dev/null || true
    fi
    rm -rf "$TMP"
}
trap cleanup EXIT

if [ -z "$PYTHON" ]; then
    echo "SKIP: python3 is required for the update tests."
    exit 0
fi

rm -rf "$TMP"
mkdir -p "$HOME_DIR/.local/bin" "$SERVE/main" "$SERVE/v9.9.9/bin" "$TMP/tmp"

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

hash_file() {
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$1" | awk '{print $1}'
    elif command -v shasum >/dev/null 2>&1; then
        shasum -a 256 "$1" | awk '{print $1}'
    else
        echo "Error: sha256sum or shasum is required." >&2
        exit 1
    fi
}

make_candidate() {
    local version="$1"

    sed "s/CODERUN_VERSION=\"2.4.0\"/CODERUN_VERSION=\"$version\"/" "$RUNNER" > "$SERVE/v9.9.9/bin/coderun"
    cp "$SERVE/v9.9.9/bin/coderun" "$SERVE/v9.9.9/bin/coderun-mac"
    chmod 755 "$SERVE/v9.9.9/bin/coderun" "$SERVE/v9.9.9/bin/coderun-mac"
    write_checksums
}

write_checksums() {
    local linux_hash
    local mac_hash

    linux_hash="$(hash_file "$SERVE/v9.9.9/bin/coderun")"
    mac_hash="$(hash_file "$SERVE/v9.9.9/bin/coderun-mac")"
    printf '%s  bin/coderun\n%s  bin/coderun-mac\n' "$linux_hash" "$mac_hash" > "$SERVE/v9.9.9/SHA256SUMS"
}

reset_target() {
    cp "$RUNNER" "$HOME_DIR/.local/bin/coderun"
    chmod 755 "$HOME_DIR/.local/bin/coderun"
}

run_update() {
    HOME="$HOME_DIR" TMPDIR="$TMP/tmp" CODERUN_RAW_BASE="$BASE_URL" \
        "$HOME_DIR/.local/bin/coderun" "$@"
}

target_hash() {
    hash_file "$HOME_DIR/.local/bin/coderun"
}

target_version() {
    sed -n 's/^CODERUN_VERSION="\([0-9][0-9.]*\)"$/\1/p' "$HOME_DIR/.local/bin/coderun" | head -n 1
}

printf '2.4.0\n' > "$SERVE/main/VERSION"
make_candidate "9.9.9"

"$PYTHON" -m http.server "$PORT" --bind 127.0.0.1 --directory "$SERVE" >/dev/null 2>&1 &
SERVER_PID=$!
sleep 0.5

# 1. Already current.
reset_target
before="$(target_hash)"
output="$(run_update --update 2>&1)"
code=$?
assert_eq "up to date exits 0" "0" "$code"
assert_contains "up to date message" "coderun is up to date (2.4.0)." "$output"
assert_eq "up to date leaves target unchanged" "$before" "$(target_hash)"

# 2. Newer version with valid checksum.
reset_target
printf '9.9.9\n' > "$SERVE/main/VERSION"
output="$(run_update --update 2>&1)"
code=$?
assert_eq "update exits 0" "0" "$code"
assert_contains "update reports new version" "coderun updated successfully to 9.9.9." "$output"
assert_eq "update installs new version" "9.9.9" "$(target_version)"
[ -x "$HOME_DIR/.local/bin/coderun" ] && ok "updated runner is executable" || bad "updated runner is executable"

# 3. check-update behavior.
reset_target
printf '2.4.0\n' > "$SERVE/main/VERSION"
output="$(run_update --check-update 2>&1)"
code=$?
assert_eq "check-update current exits 0" "0" "$code"
assert_contains "check-update current message" "coderun is up to date." "$output"

printf '9.9.9\n' > "$SERVE/main/VERSION"
output="$(run_update --check-update 2>&1)"
code=$?
assert_eq "check-update newer exits 1" "1" "$code"
assert_contains "check-update newer message" "A new version is available." "$output"

# 4. Invalid version.
reset_target
before="$(target_hash)"
printf 'banana\n' > "$SERVE/main/VERSION"
output="$(run_update --update 2>&1)"
code=$?
assert_eq "invalid version exits 1" "1" "$code"
assert_contains "invalid version message" "Error: could not read the latest version." "$output"
assert_eq "invalid version leaves target unchanged" "$before" "$(target_hash)"

# 5. Missing version.
printf '9.9.9\n' > "$SERVE/main/VERSION"
mv "$SERVE/main/VERSION" "$SERVE/main/VERSION.bak"
output="$(run_update --update 2>&1)"
code=$?
assert_eq "missing version exits 1" "1" "$code"
assert_contains "missing version message" "Error: could not check for updates." "$output"
mv "$SERVE/main/VERSION.bak" "$SERVE/main/VERSION"

# 6. Missing runner download.
reset_target
before="$(target_hash)"
mv "$SERVE/v9.9.9/bin/coderun" "$SERVE/v9.9.9/bin/coderun.bak"
output="$(run_update --update 2>&1)"
code=$?
assert_eq "download failure exits 1" "1" "$code"
assert_contains "download failure message" "Error: update download failed." "$output"
assert_eq "download failure leaves target unchanged" "$before" "$(target_hash)"
mv "$SERVE/v9.9.9/bin/coderun.bak" "$SERVE/v9.9.9/bin/coderun"

# 7. Missing SHA256SUMS.
reset_target
before="$(target_hash)"
mv "$SERVE/v9.9.9/SHA256SUMS" "$SERVE/v9.9.9/SHA256SUMS.bak"
output="$(run_update --update 2>&1)"
code=$?
assert_eq "missing checksums exits 1" "1" "$code"
assert_contains "missing checksums message" "Error: could not download SHA256SUMS" "$output"
assert_eq "missing checksums leaves target unchanged" "$before" "$(target_hash)"
mv "$SERVE/v9.9.9/SHA256SUMS.bak" "$SERVE/v9.9.9/SHA256SUMS"

# 8. Incorrect checksum.
reset_target
before="$(target_hash)"
printf '%064d  bin/coderun\n' 0 > "$SERVE/v9.9.9/SHA256SUMS"
output="$(run_update --update 2>&1)"
code=$?
assert_eq "bad checksum exits 1" "1" "$code"
assert_contains "bad checksum message" "Error: update checksum verification failed." "$output"
assert_eq "bad checksum leaves target unchanged" "$before" "$(target_hash)"

# 9. Version mismatch between VERSION and the downloaded runner.
reset_target
before="$(target_hash)"
make_candidate "8.8.8"
output="$(run_update --update 2>&1)"
code=$?
assert_eq "version mismatch exits 1" "1" "$code"
assert_contains "version mismatch message" "Error: downloaded runner version does not match 9.9.9." "$output"
assert_eq "version mismatch leaves target unchanged" "$before" "$(target_hash)"
make_candidate "9.9.9"

# 10. Not installed.
output="$(HOME="$TMP/empty-home" TMPDIR="$TMP/tmp" CODERUN_RAW_BASE="$BASE_URL" "$RUNNER" --update 2>&1)"
code=$?
assert_eq "not installed exits 1" "1" "$code"
assert_contains "not installed message" "Error: coderun is not installed at" "$output"

# 11. No temporary files left behind.
reset_target
run_update --update >/dev/null 2>&1
leftover="$(find "$TMP/tmp" -type f | head -n 1)"
assert_eq "no temporary files left" "" "$leftover"

echo
echo "Passed: $PASS  Failed: $FAIL"
[ "$FAIL" -eq 0 ]
