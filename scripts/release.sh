#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

VERSION=""
NOTES=""
PUSH=1

usage() {
    cat <<'EOF'
Usage: scripts/release.sh <version> [--notes <file>] [--no-push]

Bumps the version, syncs the platform runners, regenerates SHA256SUMS,
runs the checks, commits, tags, pushes, and creates a GitHub release.

Examples:
  scripts/release.sh 2.4.0 --notes release-notes.md
  scripts/release.sh 2.4.0 --no-push
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        --notes)
            if [ $# -lt 2 ] || [ -z "$2" ]; then
                echo "Error: --notes requires a file." >&2
                exit 1
            fi
            NOTES="$2"
            shift
            ;;
        --no-push)
            PUSH=0
            ;;
        -*)
            echo "Error: unknown option: $1" >&2
            usage >&2
            exit 1
            ;;
        *)
            if [ -n "$VERSION" ]; then
                echo "Error: unexpected argument: $1" >&2
                exit 1
            fi
            VERSION="$1"
            ;;
    esac
    shift
done

if [ -z "$VERSION" ]; then
    usage >&2
    exit 1
fi

if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Error: version must look like 2.4.0." >&2
    exit 1
fi

if [ -n "$NOTES" ] && [ ! -f "$NOTES" ]; then
    echo "Error: notes file not found: $NOTES" >&2
    exit 1
fi

if [ -n "$(git status --porcelain)" ]; then
    echo "Error: the working tree has uncommitted changes." >&2
    exit 1
fi

if git rev-parse -q --verify "refs/tags/v$VERSION" >/dev/null; then
    echo "Error: tag v$VERSION already exists." >&2
    exit 1
fi

replace_line() {
    local file="$1"
    local expression="$2"
    local temp="$file.release.$$"

    cp -p "$file" "$temp"
    sed "$expression" "$file" > "$temp"
    mv "$temp" "$file"
}

printf '%s\n' "$VERSION" > VERSION
replace_line bin/coderun 's/^CODERUN_VERSION="[0-9.]*"$/CODERUN_VERSION="'"$VERSION"'"/'
replace_line windows/coderun.ps1 's/^\$CoderunVersion = "[0-9.]*"$/$CoderunVersion = "'"$VERSION"'"/'

replace_line README.md 's/^| \*\*Current version\*\* | [0-9.]* |$/| **Current version** | '"$VERSION"' |/'
replace_line README.md 's/^### Current release: V[0-9.]*$/### Current release: V'"$VERSION"'/'
replace_line README.md 's/^├── VERSION              # Release version ([0-9.]*)$/├── VERSION              # Release version ('"$VERSION"')/'

scripts/sync.sh
scripts/checksums.sh
scripts/check.sh

git add -A

if git diff --cached --quiet; then
    echo "No file changes to commit for v$VERSION."
else
    git commit -m "release: v$VERSION"
fi

if [ "$PUSH" -eq 0 ]; then
    echo "Created local commit for v$VERSION (not pushed)."
    exit 0
fi

git tag -a "v$VERSION" -m "coderun $VERSION"
git push origin main
git push origin "v$VERSION"

if command -v gh >/dev/null 2>&1; then
    if [ -n "$NOTES" ]; then
        gh release create "v$VERSION" --repo pjprogrammers/coderun --verify-tag \
            --title "coderun v$VERSION" --notes-file "$NOTES"
    else
        gh release create "v$VERSION" --repo pjprogrammers/coderun --verify-tag \
            --title "coderun v$VERSION" --generate-notes
    fi
else
    echo "gh was not found. Create the release for v$VERSION manually."
fi

echo "Released coderun $VERSION."
