#!/usr/bin/env bash
#
# Verify that the repository is internally consistent.
#
# Checks:
#   - VERSION is valid semver and matches every source and generated runner.
#   - README version references match VERSION.
#   - The committed runners match a fresh build from src/.
#   - Required files are executable.
#   - Every Bash file parses.
#   - Every PowerShell file parses when pwsh is available.
#   - SHA256SUMS matches the release files.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

VERSION="$(tr -d '[:space:]' < VERSION)"

fail() {
    echo "FAIL: $1" >&2
    exit 1
}

[[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || fail "VERSION is not semver: $VERSION"

# Version consistency: sources and generated artifacts.
grep -qF "CODERUN_VERSION=\"$VERSION\"" src/unix/10-config.sh || fail "src/unix/10-config.sh version does not match VERSION"
grep -qF "CODERUN_VERSION=\"$VERSION\"" bin/coderun || fail "bin/coderun version does not match VERSION"
grep -qF "CODERUN_VERSION=\"$VERSION\"" bin/coderun-mac || fail "bin/coderun-mac version does not match VERSION"
grep -qF "\$CoderunVersion = \"$VERSION\"" src/windows/00-header.ps1 || fail "src/windows/00-header.ps1 version does not match VERSION"
grep -qF "\$CoderunVersion = \"$VERSION\"" windows/coderun.ps1 || fail "windows/coderun.ps1 version does not match VERSION"

# README version references.
grep -qF "| **Current version** | $VERSION |" README.md || fail "README current version does not match VERSION"
grep -qF "### Current release: V$VERSION" README.md || fail "README current release does not match VERSION"
grep -qF "# Release version ($VERSION)" README.md || fail "README project structure version does not match VERSION"

# Generated artifacts must match a fresh build.
./scripts/build.sh --check >/dev/null || fail "generated runners are out of date; run scripts/build.sh"

# Required executables.
for file in \
    bin/coderun \
    bin/coderun-mac \
    install.sh \
    install-mac.sh \
    install.ps1 \
    install.cmd \
    windows/coderun.ps1 \
    scripts/build.sh \
    scripts/checksums.sh \
    scripts/check.sh \
    scripts/release.sh \
    tests/fake-tool.sh \
    tests/run-bash-tests.sh \
    tests/update-bash-tests.sh \
    tests/installer-tests.sh; do
    [ -x "$file" ] || fail "$file is not executable"
done

# Bash syntax for sources, generated runners, and tooling.
for file in \
    src/unix/*.sh \
    bin/coderun \
    bin/coderun-mac \
    install.sh \
    install-mac.sh \
    scripts/*.sh \
    tests/*.sh \
    tests/lib/*.sh; do
    [ -e "$file" ] || continue
    bash -n "$file" || fail "Bash syntax check failed: $file"
done

# PowerShell syntax for the source modules, generated runner, and installer.
if command -v pwsh >/dev/null 2>&1; then
    pwsh -NoProfile -Command '
        $files = @(
            "src/windows/00-header.ps1",
            "src/windows/10-languages.ps1",
            "src/windows/20-output.ps1",
            "src/windows/30-completions.ps1",
            "src/windows/40-info.ps1",
            "src/windows/50-update.ps1",
            "src/windows/60-execution.ps1",
            "src/windows/70-cli.ps1",
            "windows/coderun.ps1",
            "install.ps1"
        )

        foreach ($file in $files) {
            $errors = $null
            [System.Management.Automation.Language.Parser]::ParseFile(
                (Resolve-Path $file),
                [ref]$null,
                [ref]$errors
            ) | Out-Null

            if ($errors.Count -gt 0) {
                $errors | ForEach-Object { Write-Host $_.Message }
                exit 1
            }
        }
    ' >/dev/null || fail "PowerShell syntax check failed"
fi

# Release checksums.
if command -v sha256sum >/dev/null 2>&1; then
    sha256sum -c SHA256SUMS >/dev/null || fail "SHA256SUMS does not match the tracked files"
elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 -c SHA256SUMS >/dev/null || fail "SHA256SUMS does not match the tracked files"
fi

echo "All consistency checks passed for coderun $VERSION."
