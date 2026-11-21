# Release

coderun follows [Semantic Versioning](https://semver.org/):

| Component | Meaning |
| --- | --- |
| MAJOR | Incompatible changes to the command or its behaviour |
| MINOR | New, backward-compatible features |
| PATCH | Backward-compatible bug fixes |

The release version lives in `VERSION` and is mirrored in:

- `src/unix/10-config.sh`
- `src/windows/00-header.ps1`
- the generated runners
- the README

`scripts/check.sh` fails when any of those drift.

---

## Release checklist

1. Make sure the working tree is clean.
2. Update `README.md` with the release highlights.
3. Run the full test suite:

   ```bash
   ./scripts/build.sh
   ./scripts/check.sh
   ./tests/run-bash-tests.sh
   ./tests/update-bash-tests.sh
   ./tests/installer-tests.sh
   ```

4. Run the Windows suites if you have PowerShell:

   ```powershell
   pwsh -NoProfile -File tests/run-powershell-tests.ps1
   pwsh -NoProfile -File tests/installer-tests.ps1
   ```

5. Run the release script with release notes:

   ```bash
   ./scripts/release.sh 2.4.1 --notes release-notes.md
   ```

6. Confirm the GitHub release and CI run.

For a dry run that creates a local commit without pushing:

```bash
./scripts/release.sh 2.4.1 --no-push
```

---

## What `scripts/release.sh` does

1. Validates the version format and that the tag does not already exist.
2. Refuses to run with uncommitted changes.
3. Writes the new version to `VERSION`, the Unix source, and the Windows source.
4. Updates the README version references.
5. Runs `scripts/build.sh` to regenerate all runners.
6. Runs `scripts/checksums.sh` to regenerate `SHA256SUMS`.
7. Runs `scripts/check.sh`.
8. Commits the changes as `release: v<version>`.
9. Tags the commit as `v<version>`.
10. Pushes `main` and the tag.
11. Creates a GitHub release with `gh` when available.

---

## Published artifacts

Each release tag contains the files that installers and updaters use:

| File | Purpose |
| --- | --- |
| `bin/coderun` | Generated Linux runner. |
| `bin/coderun-mac` | macOS runner copy. |
| `windows/coderun.ps1` | Windows runner. |
| `install.sh` | Linux installer. |
| `install-mac.sh` | macOS installer. |
| `install.ps1` | Windows installer. |
| `install.cmd` | Command Prompt wrapper. |
| `SHA256SUMS` | SHA-256 checksums for the release files. |
| `VERSION` | Published version used by `--check-update` and `--update`. |

`--update` downloads from the versioned tag, not from `main`:

```text
<raw-base>/v<version>/bin/coderun
<raw-base>/v<version>/bin/coderun-mac
<raw-base>/v<version>/windows/coderun.ps1
<raw-base>/v<version>/SHA256SUMS
```

`--check-update` reads `<raw-base>/main/VERSION`.

---

## Version bump mechanics

The release script uses `sed` to update exactly these lines:

```text
CODERUN_VERSION="x.y.z"          # src/unix/10-config.sh
$CoderunVersion = "x.y.z"        # src/windows/00-header.ps1
```

It then rebuilds the artifacts, so never edit the generated version lines by
hand.

---

## Checksums

Regenerate checksums whenever a release file changes:

```bash
./scripts/checksums.sh
```

The script hashes:

- `bin/coderun`
- `bin/coderun-mac`
- `windows/coderun.ps1`
- `install.sh`
- `install-mac.sh`
- `install.ps1`
- `install.cmd`

`scripts/check.sh` verifies `SHA256SUMS` against the working tree.

---

## Rollback

If a release is broken:

1. Do not move or reuse the tag; users may already have downloaded it.
2. Publish a patch release with the fix.
3. If the updater itself is broken, document the manual upgrade path in the
   README and release notes.

The update flow is intentionally conservative: a failed version check,
download, embedded-version check, or checksum verification leaves the installed
runner untouched.
