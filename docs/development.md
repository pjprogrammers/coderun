# Development

This guide covers the maintainer workflow: building the runners, running tests,
and keeping the generated artifacts in sync.

---

## Quick start

```bash
git clone https://github.com/pjprogrammers/coderun.git
cd coderun

./scripts/build.sh      # regenerate the single-file runners
./scripts/check.sh      # consistency checks
./tests/run-bash-tests.sh
```

You do not need a compiler toolchain to run the tests. The test suite uses fake
toolchain shims for every language.

---

## Prerequisites

| Tool | Needed for |
| --- | --- |
| Bash 3.2+ | Running the Unix runner and build scripts. |
| `git` | Normal development. |
| `shellcheck` (optional) | Linting Bash. CI installs it. |
| `pwsh` (optional) | Parsing and testing the Windows runner on any platform. |
| `python3` (optional) | Running the update tests, which start a local HTTP server. |

No language toolchains (GCC, Node, Go, etc.) are required for development. They
are only required to run real programs.

---

## The build step

The shipped runners are generated from `src/`.

```bash
./scripts/build.sh          # build and write the artifacts
./scripts/build.sh --check  # verify committed artifacts are current
```

`scripts/build.sh`:

1. concatenates `src/unix/*.sh` into `bin/coderun`;
2. runs `bash -n` on the result;
3. concatenates `src/windows/*.ps1` into `windows/coderun.ps1`;
4. parses the PowerShell result when `pwsh` is available;
5. copies `bin/coderun` to `bin/coderun-mac` for the macOS installer and updater.

### Generated files

Do **not** edit these by hand:

- `bin/coderun`
- `bin/coderun-mac`
- `windows/coderun.ps1`

Edit the matching module in `src/unix/` or `src/windows/`, then rebuild. The
generated files start with a banner that lists their source modules.

---

## Running the runner from a checkout

After building:

```bash
./bin/coderun --version
./bin/coderun --list
./bin/coderun path/to/program.py
```

To test the installed path behaviour without touching your real installation:

```bash
HOME="$(mktemp -d)" ./install.sh
```

The installer tests do this automatically.

---

## Tests

Run everything:

```bash
make test
```

Or run the suites individually:

```bash
./tests/run-bash-tests.sh          # Unix behaviour
./tests/update-bash-tests.sh       # update and checksum flows
./tests/installer-tests.sh         # Unix installers
pwsh -NoProfile -File tests/run-powershell-tests.ps1
pwsh -NoProfile -File tests/installer-tests.ps1
```

On Linux, simulate macOS compiler selection:

```bash
CODERUN_TEST_OS=Darwin ./tests/run-bash-tests.sh
```

See [Testing](testing.md) for details on the fake toolchains and update server.

---

## Consistency checks

```bash
./scripts/check.sh
```

This verifies:

- `VERSION` is valid semver;
- the version matches the sources, generated runners, and README;
- the committed runners match a fresh build;
- required files are executable;
- all Bash files parse;
- all PowerShell files parse when `pwsh` is available;
- `SHA256SUMS` matches the release files.

If you changed a release file, regenerate the checksums:

```bash
./scripts/checksums.sh
```

---

## Linting

CI runs ShellCheck on every Bash file:

```bash
shellcheck -S warning \
    bin/coderun \
    install.sh \
    install-mac.sh \
    scripts/*.sh \
    src/unix/*.sh \
    tests/*.sh \
    tests/lib/*.sh
```

CI runs PSScriptAnalyzer on the Windows runner and installer:

```powershell
Invoke-ScriptAnalyzer -Path windows/coderun.ps1 -Settings .github/PSScriptAnalyzerSettings.psd1
Invoke-ScriptAnalyzer -Path install.ps1 -Settings .github/PSScriptAnalyzerSettings.psd1
```

---

## Common tasks

| Task | Command |
| --- | --- |
| Rebuild the runners | `./scripts/build.sh` |
| Verify generated files are current | `./scripts/build.sh --check` |
| Run all consistency checks | `./scripts/check.sh` |
| Run all Unix tests | `make test` |
| Regenerate release checksums | `./scripts/checksums.sh` |
| Build the release archives | `./scripts/package-release.sh [output-dir]` |
| Bump and release a version | `./scripts/release.sh <version>` |
| See available make targets | `make` or `make help` |

---

## Troubleshooting

### `generated runners are stale`

You edited `src/` but did not rebuild. Run:

```bash
./scripts/build.sh
```

Commit the regenerated files.

### `SHA256SUMS does not match the tracked files`

A release file changed. Regenerate the checksums:

```bash
./scripts/checksums.sh
```

### PowerShell parser is not available

`scripts/build.sh` and `scripts/check.sh` skip PowerShell parsing when `pwsh`
is not installed. CI still checks it on Windows. Install PowerShell 7 if you
want local validation:

<https://learn.microsoft.com/powershell/scripting/install/installing-powershell>

### The update tests skip

They require `python3` to serve a local directory over HTTP. Install Python 3
and rerun `./tests/update-bash-tests.sh`.
