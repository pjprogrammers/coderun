#!/usr/bin/env bash
# Package the CodeRun release archives consumed by installers.
#
# Usage:
#   ./scripts/package-release.sh [output-directory]
#
# The output directory defaults to dist/. It receives:
#
#   coderun-linux-x64.tar.gz
#   coderun-linux-arm64.tar.gz
#   coderun-macos-x64.tar.gz
#   coderun-macos-arm64.tar.gz
#   coderun-windows-x64.zip
#   coderun-windows-arm64.zip
#   SHA256SUMS
#
# The Unix and Windows runners are single files that work on both CPU
# architectures. The per-architecture archives exist so installers can select
# an asset by OS and architecture without special cases.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

OUT="${1:-$ROOT/dist}"
VERSION="$(tr -d '[:space:]' < VERSION)"

if [[ -z "$VERSION" ]]; then
    echo "Error: VERSION is empty." >&2
    exit 1
fi

if [[ ! -f bin/coderun || ! -f bin/coderun-mac || ! -f windows/coderun.ps1 ]]; then
    echo "Error: runners are missing. Run ./scripts/build.sh first." >&2
    exit 1
fi

if [[ ! -f windows/coderun.cmd ]]; then
    echo "Error: windows/coderun.cmd is missing." >&2
    exit 1
fi

if ! command -v zip >/dev/null 2>&1; then
    echo "Error: zip is required to build the Windows archives." >&2
    exit 1
fi

TEMP_DIR="${TMPDIR:-/tmp}/coderun-release.$$"
rm -rf "$TEMP_DIR"
trap 'rm -rf "$TEMP_DIR"' EXIT

rm -rf "$OUT"
mkdir -p "$OUT"

# Stage the files that ship inside every Unix archive.
stage_unix() {
    local runner="$1"
    local directory="$TEMP_DIR/unix"

    rm -rf "$directory"
    mkdir -p "$directory"
    install -m755 "$runner" "$directory/coderun"
    install -m644 README.md LICENSE VERSION "$directory/"
    printf '%s' "$directory"
}

# Stage the files that ship inside every Windows archive.
stage_windows() {
    local directory="$TEMP_DIR/windows"

    rm -rf "$directory"
    mkdir -p "$directory"
    install -m644 windows/coderun.ps1 "$directory/coderun.ps1"
    install -m644 windows/coderun.cmd "$directory/coderun.cmd"
    install -m644 README.md LICENSE VERSION "$directory/"
    printf '%s' "$directory"
}

make_tar() {
    local asset="$1"
    local runner="$2"
    local directory

    directory="$(stage_unix "$runner")"
    tar -czf "$OUT/$asset" -C "$directory" \
        coderun README.md LICENSE VERSION
    echo "built $asset"
}

make_zip() {
    local asset="$1"
    local directory

    directory="$(stage_windows)"
    (
        cd "$directory"
        zip -q -X "$OUT/$asset" coderun.ps1 coderun.cmd README.md LICENSE VERSION
    )
    echo "built $asset"
}

echo "==> building runners"
./scripts/build.sh

echo "==> packaging CodeRun $VERSION"
make_tar coderun-linux-x64.tar.gz bin/coderun
make_tar coderun-linux-arm64.tar.gz bin/coderun
make_tar coderun-macos-x64.tar.gz bin/coderun-mac
make_tar coderun-macos-arm64.tar.gz bin/coderun-mac
make_zip coderun-windows-x64.zip
make_zip coderun-windows-arm64.zip

echo "==> writing SHA256SUMS"
if command -v sha256sum >/dev/null 2>&1; then
    (
        cd "$OUT"
        sha256sum coderun-linux-x64.tar.gz coderun-linux-arm64.tar.gz \
            coderun-macos-x64.tar.gz coderun-macos-arm64.tar.gz \
            coderun-windows-x64.zip coderun-windows-arm64.zip > SHA256SUMS
    )
elif command -v shasum >/dev/null 2>&1; then
    (
        cd "$OUT"
        shasum -a 256 coderun-linux-x64.tar.gz coderun-linux-arm64.tar.gz \
            coderun-macos-x64.tar.gz coderun-macos-arm64.tar.gz \
            coderun-windows-x64.zip coderun-windows-arm64.zip > SHA256SUMS
    )
else
    echo "Error: sha256sum or shasum is required." >&2
    exit 1
fi

echo "==> verifying Linux archive"
VERIFY_DIR="$TEMP_DIR/verify"
mkdir -p "$VERIFY_DIR"
tar -xzf "$OUT/coderun-linux-x64.tar.gz" -C "$VERIFY_DIR"
bash -n "$VERIFY_DIR/coderun"
version_output="$("$VERIFY_DIR/coderun" --version)"
if [[ "$version_output" != "coderun $VERSION" ]]; then
    echo "Error: packaged runner reported '$version_output'." >&2
    exit 1
fi

echo
echo "Wrote release assets to $OUT"
cat "$OUT/SHA256SUMS"
