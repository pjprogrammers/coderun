# Architecture

coderun is a small, dependency-free command-line runner. It detects a source
file's language, chooses the right compiler or interpreter, runs the program,
and passes through the exit code.

This document explains the design constraints, the source layout, and the
extension points.

---

## Design goals

1. **One command, many languages.** A single interface hides the differences
   between compilers, interpreters, and runtime flags.
2. **Zero installation dependencies.** Users need Bash or PowerShell, not a
   package manager, build system, or daemon.
3. **Predictable exit codes.** The compiler or program status is never masked.
4. **Safe updates.** Self-updates download a versioned file and verify it
   before replacing the installed runner.
5. **Easy maintenance.** Sources are small, single-purpose modules even though
   the shipped artifact is one file.

---

## Why the shipped runners are single files

The installers copy one file into place:

```text
install.sh / install-mac.sh  ->  ~/.local/bin/coderun
install.ps1                  ->  %USERPROFILE%\bin\coderun.ps1
```

`coderun --update` downloads one file from the versioned release tag and
verifies its SHA-256 checksum before replacing the installed copy. Keeping the
artifact self-contained makes installation, uninstallation, offline copying,
and checksum verification simple.

Maintainers still want modules, so the repository uses a **source-to-artifact**
pipeline:

```text
src/unix/*.sh    ──> scripts/build.sh ──> bin/coderun ──> bin/coderun-mac

src/windows/*.ps1 ─> scripts/build.sh ──> windows/coderun.ps1
```

The generated files are committed because they are the release artifacts.
`scripts/build.sh --check` fails when they are stale.

> **Rule:** never edit `bin/coderun`, `bin/coderun-mac`, or
> `windows/coderun.ps1` by hand. Edit `src/` and run `./scripts/build.sh`.

---

## Repository layout

```text
coderun/
├── src/
│   ├── unix/                 # Source for the Bash runner
│   └── windows/              # Source for the PowerShell runner
├── bin/
│   ├── coderun               # Generated Linux/macOS runner
│   └── coderun-mac           # Generated macOS copy
├── windows/
│   ├── coderun.ps1           # Generated Windows runner
│   └── coderun.cmd           # Command Prompt launcher
├── scripts/                  # Build, check, checksum, package, and release tooling
├── tests/                    # Behaviour, update, and installer tests
├── docs/                     # Maintainer documentation (this directory)
├── .github/workflows/        # CI and release-asset publishing
├── install.sh                # Linux installer
├── install-mac.sh            # macOS installer
├── install.ps1               # Windows installer
├── install.cmd               # Command Prompt wrapper for install.ps1
├── VERSION                   # Release version
└── SHA256SUMS                # Checksums for release files
```

---

## Unix runner modules

The Unix runner is built by concatenating these modules in order.

| Module | Responsibility |
| --- | --- |
| `10-config.sh` | Version, URLs, install paths, platform detection, temp-file cleanup, quiet flag. |
| `20-output.sh` | Informational logging, lowercasing, and timing helpers. |
| `30-languages.sh` | The language table, name/extension lookup, and dependency checks. |
| `40-help.sh` | The `--help` text. |
| `50-completions.sh` | Bash, Zsh, Fish, and PowerShell completion output. |
| `60-info.sh` | `--info` and script-path resolution. |
| `70-update.sh` | Downloaders, version comparison, `--check-update`, `--update`, and `--uninstall`. |
| `80-compile.sh` | Artifact naming, compilation commands, and `--clean`. |
| `90-run.sh` | Interpreter and compiled-program dispatch. |
| `95-cli.sh` | Argument parsing, validation, actions, and the `main` flow. |
| `99-main.sh` | Calls `main "$@"`. |

### Data flow

```text
main "$@"
  │
  ├─ parse_arguments        fill mode/action/file/program_args
  ├─ handle_action          --list, --check, --info, --update, ...
  ├─ validate_invocation    file exists, extension resolves, options valid
  └─ execute
       ├─ clean             clean_file
       ├─ compile           compile_file
       └─ run               run_file
```

The parser stops at the source file. Everything after it is stored in
`program_args` and passed to the program unchanged, except for one optional
`--` separator.

### Shared state

Bash functions do not return structured values cleanly, so the runner uses a
documented set of globals:

| Variable | Set by | Meaning |
| --- | --- | --- |
| `mode` | parser | `run`, `compile`, or `clean`. |
| `action` | parser | `list`, `check`, `info`, `check-update`, `update`, `uninstall`, or `completions`. |
| `file`, `program_args` | parser | Source file and forwarded program arguments. |
| `output_opt`, `runtime_opt` | parser | `-o/--output` and `--runtime` values. |
| `check_target`, `check_strict` | parser | `--check <lang>` and `--check --strict`. |
| `list_verbose`, `time_it`, `completion_shell` | parser | Remaining flags. |
| `dir`, `name`, `base`, `ext` | validation | Source path components. |
| `LANG_ID`, `LANG_NAME`, `LANG_TYPE`, `LANG_TOOLS` | validation | Resolved language record. |
| `COMPILE_OUTPUT` | `compile_artifact` | Artifact path for the current compile. |
| `MISSING_TOOLS` | `missing_tools` | Result of the last tool check. |

When adding a module, keep this contract explicit. Avoid adding hidden globals
that another module must set in a particular order.

---

## Windows runner modules

The Windows runner follows the same idea.

| Module | Responsibility |
| --- | --- |
| `00-header.ps1` | `param()`, version, raw URL, runner path, compilers, quiet flag. |
| `10-languages.ps1` | Language table, lookup, and dependency checks. |
| `20-output.ps1` | `Write-Info` and `Show-Help`. |
| `30-completions.ps1` | Shell completion output. |
| `40-info.ps1` | `--info`. |
| `50-update.ps1` | Version comparison, update, and uninstall. |
| `60-execution.ps1` | Tool checks, compile, and clean. |
| `70-cli.ps1` | Parsing, validation, actions, and run dispatch. |

PowerShell requires `param()` to be the first statement in the generated file.
The build banner is comments only, so this remains valid.

---

## Adding a language

1. Add a record to `LANGUAGES` in `src/unix/30-languages.sh` and to
   `$Languages` in `src/windows/10-languages.ps1`.
2. Add the compile command to `compile_file` in `src/unix/80-compile.sh` and
   `Invoke-Compile` in `src/windows/60-execution.ps1`, if the language is
   compiled.
3. Add the run command to `run_file` / `run_compiled` in `src/unix/90-run.sh`
   and to the run switch in `src/windows/70-cli.ps1`.
4. Add cleanup rules to `clean_file` and `Invoke-Clean` when the language
   produces artifacts beyond the default binary.
5. Update the help text, the README language table, and the test dispatch
   lists.
6. Run `./scripts/build.sh` and the test suites.

The language table is the single source of truth for names, extensions, type,
and required tools. Avoid duplicating that metadata elsewhere.

---

## Adding a command-line option

1. Add the flag to `parse_arguments` in `src/unix/95-cli.sh` and the parser in
   `src/windows/70-cli.ps1`.
2. Add validation to `validate_invocation` (or a focused helper).
3. Implement the behaviour in a module that owns the relevant responsibility.
4. Update `show_help`, the completion scripts, the README command reference,
   and the tests.
5. Run `./scripts/build.sh` and `./scripts/check.sh`.

Options are only recognized **before** the source file. That rule keeps program
arguments unambiguous and must be preserved.

---

## Update security model

`--update` follows this sequence:

1. Read `VERSION` from `main`.
2. Compare it with the installed `CODERUN_VERSION`.
3. Download the platform runner from `/v<version>/...`.
4. Check the first line is the expected script header.
5. Check the embedded `CODERUN_VERSION` matches the announced release.
6. Download `SHA256SUMS` from the same tag and verify the file hash.
7. `chmod` and atomically move the temporary file into place.

Any failure leaves the installed runner untouched. Temporary files are removed
by an `EXIT` trap. The Windows runner uses the same sequence with
`Invoke-WebRequest` and `Get-FileHash`.

---

## Portability notes

- The Unix runner targets Bash 3.2 (the version shipped with macOS). Avoid
  associative arrays, namerefs, and other Bash 4+ features.
- The Windows runner targets Windows PowerShell 5.1 and PowerShell 7+. Avoid
  APIs that only exist in one edition.
- File paths may contain spaces. Quote every expansion that becomes an
  argument.
- Extensions are matched case-insensitively.
- Do not add runtime dependencies to the shipped runners. `--check`,
  `--check-update`, and `--update` may use `curl`/`wget` and a SHA-256 tool, but
  the runner must work without them for normal execution.

---

## Why generated files are committed

Committing the generated runners means:

- users can install from a clone without a build step;
- release checksums can cover exactly the bytes users download;
- `--update` can replace one file;
- CI can verify that `src/` and the artifacts agree.

The trade-off is that a source change is not complete until the generated
artifacts are rebuilt. `scripts/build.sh --check` and `scripts/check.sh` enforce
that.
