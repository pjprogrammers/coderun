#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FILES=(
    "bin/coderun"
    "bin/coderun-mac"
    "windows/coderun.ps1"
    "install.sh"
    "install-mac.sh"
    "install.ps1"
    "install.cmd"
)

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

cd "$ROOT"

{
    for file in "${FILES[@]}"; do
        printf '%s  %s\n' "$(hash_file "$file")" "$file"
    done
} > SHA256SUMS

echo "Wrote SHA256SUMS."
