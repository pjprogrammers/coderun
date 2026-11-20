#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

VERSION="$(tr -d '[:space:]' < VERSION)"

fail() {
    echo "FAIL: $1" >&2
    exit 1
}

[[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || fail "VERSION is not semver: $VERSION"

grep -qF "CODERUN_VERSION=\"$VERSION\"" bin/coderun || fail "bin/coderun version does not match VERSION"
grep -qF "CODERUN_VERSION=\"$VERSION\"" bin/coderun-mac || fail "bin/coderun-mac version does not match VERSION"
grep -qF "CODERUN_VERSION=\"$VERSION\"" coderun || fail "root coderun version does not match VERSION"
grep -qF "\$CoderunVersion = \"$VERSION\"" windows/coderun.ps1 || fail "windows/coderun.ps1 version does not match VERSION"
grep -qF "| **Current version** | $VERSION |" README.md || fail "README current version does not match VERSION"
grep -qF "### Current release: V$VERSION" README.md || fail "README current release does not match VERSION"
grep -qF "# Release version ($VERSION)" README.md || fail "README project structure version does not match VERSION"

cmp -s bin/coderun bin/coderun-mac || fail "bin/coderun and bin/coderun-mac differ; run scripts/sync.sh"
cmp -s bin/coderun coderun || fail "bin/coderun and root coderun differ; run scripts/sync.sh"

for file in coderun bin/coderun bin/coderun-mac install.sh install-mac.sh install.ps1 install.cmd windows/coderun.ps1 scripts/sync.sh scripts/checksums.sh scripts/check.sh scripts/release.sh tests/fake-tool.sh tests/run-bash-tests.sh tests/update-bash-tests.sh tests/installer-tests.sh; do
    [ -x "$file" ] || fail "$file is not executable"
done

bash -n bin/coderun
bash -n bin/coderun-mac
bash -n coderun
bash -n install.sh
bash -n install-mac.sh
bash -n scripts/sync.sh
bash -n scripts/checksums.sh
bash -n scripts/check.sh
bash -n scripts/release.sh
bash -n tests/run-bash-tests.sh
bash -n tests/update-bash-tests.sh
bash -n tests/installer-tests.sh

if command -v sha256sum >/dev/null 2>&1; then
    sha256sum -c SHA256SUMS >/dev/null || fail "SHA256SUMS does not match the tracked files"
elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 -c SHA256SUMS >/dev/null || fail "SHA256SUMS does not match the tracked files"
fi

if command -v pwsh >/dev/null 2>&1; then
    pwsh -NoProfile -Command '
        $errors = $null
        [System.Management.Automation.Language.Parser]::ParseFile("windows/coderun.ps1", [ref]$null, [ref]$errors) | Out-Null
        if ($errors.Count -gt 0) { $errors | ForEach-Object { Write-Host $_.Message }; exit 1 }
        $errors = $null
        [System.Management.Automation.Language.Parser]::ParseFile("install.ps1", [ref]$null, [ref]$errors) | Out-Null
        if ($errors.Count -gt 0) { $errors | ForEach-Object { Write-Host $_.Message }; exit 1 }
    ' >/dev/null || fail "PowerShell syntax check failed"
fi

echo "All consistency checks passed for coderun $VERSION."
