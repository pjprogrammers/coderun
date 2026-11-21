# Contributing to coderun

Thanks for helping improve coderun. This guide gets you from a clone to a
tested pull request.

---

## Where things live

| Path | What it is |
| --- | --- |
| `src/unix/` | Source for the Bash runner (Linux and macOS). |
| `src/windows/` | Source for the PowerShell runner (Windows). |
| `bin/`, `windows/coderun.ps1` | Generated release artifacts. Do not edit by hand. |
| `scripts/` | Build, check, checksum, package, and release tooling. |
| `tests/` | Behaviour, update, and installer tests. |
| `docs/` | Maintainer documentation. |
| `README.md` | User documentation. |

The architecture and module map are documented in
[docs/architecture.md](docs/architecture.md).

---

## Development workflow

1. **Fork and clone** the repository.
2. **Create a branch** for your change.
3. **Edit the source modules** in `src/`, not the generated runners.
4. **Build** the single-file runners:

   ```bash
   ./scripts/build.sh
   ```

5. **Run the checks**:

   ```bash
   ./scripts/check.sh
   ```

6. **Run the tests** that cover your change. At minimum:

   ```bash
   ./tests/run-bash-tests.sh
   ./tests/update-bash-tests.sh
   ./tests/installer-tests.sh
   ```

   For Windows changes, run:

   ```powershell
   pwsh -NoProfile -File tests/run-powershell-tests.ps1
   pwsh -NoProfile -File tests/installer-tests.ps1
   ```

7. **Regenerate checksums** if a release file changed:

   ```bash
   ./scripts/checksums.sh
   ```

8. **Commit** with a focused message and open a pull request.

You can also use the Makefile:

```bash
make build
make check
make test
```

---

## Adding a language

See [Adding a language](docs/architecture.md#adding-a-language). In short:

1. Add the language record to both runners' tables.
2. Add compile, run, and clean handling.
3. Update help, README, and the dispatch tests.
4. Rebuild and run the tests.

---

## Adding an option

See [Adding a command-line option](docs/architecture.md#adding-a-command-line-option).
Remember that options are only parsed before the source file; everything after
the file belongs to the program.

---

## Code style

Follow [docs/code-style.md](docs/code-style.md). The short version:

- Bash: four spaces, quote expansions, `local` variables, Bash 3.2 compatible.
- PowerShell: four spaces, approved verbs, `param()` blocks, 5.1 compatible.
- Comment the why, not the what.
- Remove dead code.
- Never edit generated files.

---

## Testing expectations

- Add or update tests for behaviour changes.
- Cover error paths, exit codes, argument forwarding, and paths with spaces.
- Use the fake toolchain in `tests/fake-tool.sh`; do not require real language
  toolchains.
- Keep tests independent and order-insensitive.

See [docs/testing.md](docs/testing.md) for the test architecture.

---

## Documentation

- User-facing changes belong in `README.md`.
- Maintainer-facing changes belong in `docs/`.
- Keep the help text, README command reference, and completion scripts in
  sync.

---

## Pull request checklist

- [ ] Change is in `src/`, not in a generated file.
- [ ] `./scripts/build.sh` has been run.
- [ ] `./scripts/check.sh` passes.
- [ ] Relevant test suites pass.
- [ ] Help text, README, and docs are updated.
- [ ] `SHA256SUMS` is regenerated if a release file changed.
- [ ] The pull request describes the change and the platform tested.

---

## Reporting bugs

Include:

- the output of `coderun --version`;
- the output of `coderun --info`;
- the command you ran;
- the expected and actual behaviour;
- your operating system and shell.

If the problem is language-specific, include the output of:

```bash
coderun --check <language>
```

---

## License

By contributing, you agree that your contributions are licensed under the
project's MIT license. See [LICENSE](LICENSE).
