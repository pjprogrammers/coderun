#!/usr/bin/env bash
#
# Shared file-hash helper for the Unix test suites.

# Print the SHA-256 hash of a file. Exits with an error when no hashing tool
# is available.
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
