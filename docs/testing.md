# Testing

coderun has five test suites: three Unix suites and two Windows suites. They
are designed to run without installing any language toolchains.

---

## Test suites

| Suite | Platform | What it covers |
| --- | --- | --- |
| `tests/run-bash-tests.sh` | Linux/macOS | Version, help, listing, dependency checks, argument forwarding, compile/clean/output, every language dispatch, completions, and usage errors. |
| `tests/update-bash-tests.sh` | Linux/macOS | Version checks, update success, invalid versions, missing files, checksum failures, version mismatches, and temporary-file cleanup. |
| `tests/installer-tests.sh` | Linux/macOS | Linux and macOS installers, missing tool warnings, reinstall behaviour, PATH entries, and paths containing spaces. |
| `tests/run-powershell-tests.ps1` | Windows | The Windows equivalent of the Unix behaviour and update suites. |
| `tests/installer-tests.ps1` | Windows | Windows installer, PATH handling, and launcher creation. |

Run the Unix suites:

```bash
./tests/run-bash-tests.sh
./tests/update-bash-tests.sh
./tests/installer-tests.sh
```

Run the Windows suites:

```powershell
pwsh -NoProfile -File tests/run-powershell-tests.ps1
pwsh -NoProfile -File tests/installer-tests.ps1
```

CI runs the Windows suites under both PowerShell 7 and Windows PowerShell 5.1.

---

## Shared assertions

The Unix suites source `tests/lib/assertions.sh` for `ok`, `bad`, `assert_eq`,
`assert_contains`, and `assert_not_contains`. The update suite also sources
`tests/lib/hash.sh` for SHA-256 hashing.

Each suite initializes `PASS` and `FAIL` before sourcing the helpers. At the
end, it prints a summary and exits non-zero when any test failed.

When adding a test:

1. Give it a short, specific name.
2. Prefer asserting on observable output, exit codes, and the shim log rather
   than internal functions.
3. Keep tests independent. Do not rely on the order of other tests.
4. Use the existing `assert_*` helpers.

---

## Fake toolchains

`tests/fake-tool.sh` is a single shim that behaves like every compiler and
interpreter. The test setup creates symlinks such as `gcc`, `python3`, and
`node` pointing at it, then puts that directory first on `PATH`.

The shim:

- records every invocation and its arguments in `SHIM_LOG`, pipe-separated;
- creates a runnable artifact when a compiler asks for an output path;
- exits with `SHIM_EXIT` when set, so tests can verify exit-code forwarding;
- lets compiled artifacts exit with `SHIM_PROGRAM_EXIT`.

This is why the tests can cover all 26 languages without installing anything.

The tests also build a `safe-bin` directory containing only the utilities the
runner is allowed to use. That keeps the runner from accidentally depending on
tools that are present on the developer's machine.

---

## macOS simulation

The Unix runner detects the platform with `uname`. On Linux CI, the test suite
can simulate macOS:

```bash
CODERUN_TEST_OS=Darwin ./tests/run-bash-tests.sh
```

The suite then expects `clang`/`clang++` instead of `gcc`/`g++` and places a
fake `uname` on `PATH` that prints `Darwin`.

---

## Update test server

`tests/update-bash-tests.sh` starts a local Python HTTP server rooted at a
temporary directory that mimics the GitHub raw layout:

```text
main/VERSION
v9.9.9/bin/coderun
v9.9.9/bin/coderun-mac
v9.9.9/SHA256SUMS
```

It points the runner at that server with `CODERUN_RAW_BASE` and then exercises:

- already up to date;
- successful update;
- `--check-update` when current and when newer;
- invalid and missing version files;
- missing runner downloads;
- missing checksums;
- incorrect checksums;
- a runner whose embedded version does not match the announced release;
- updating when the runner is not installed;
- no leftover temporary files.

The Windows suite uses the same idea with a temporary HTTP listener.

---

## Installer tests

The installer suites run the real installers with a temporary `HOME`
(Linux/macOS) or `USERPROFILE` (Windows). They verify:

- installation succeeds without language toolchains;
- missing tools produce warnings, not errors;
- reinstall reports an upgrade and does not duplicate PATH entries;
- paths containing spaces work;
- the installed runner is executable and matches the built artifact;
- macOS prefers `.zshrc` and creates `.zprofile` when needed.

---

## CI matrix

GitHub Actions runs:

- Ubuntu and macOS: syntax, ShellCheck, consistency checks, runner tests,
  macOS simulation on Linux, update tests, and installer tests.
- Windows: PSScriptAnalyzer, parse and version checks, runner tests, and
  installer tests under PowerShell 7 and Windows PowerShell 5.1.

See `.github/workflows/ci.yml` for the exact commands.
