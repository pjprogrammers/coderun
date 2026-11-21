#!/usr/bin/env bash
#
# Shared assertions for the Unix test suites.
#
# The calling script must initialize PASS and FAIL before sourcing this file.

# Record a passing test.
ok() {
    echo "PASS: $1"
    PASS=$((PASS + 1))
}

# Record a failing test. The optional second argument is printed as detail.
bad() {
    echo "FAIL: $1"
    if [ $# -gt 1 ]; then
        printf '%s\n' "$2"
    fi
    FAIL=$((FAIL + 1))
}

# Assert that two strings are equal.
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

# Assert that a string contains a literal substring.
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

# Assert that a string does not contain a literal substring.
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
