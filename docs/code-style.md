# Code style

The project values small modules, explicit behaviour, and predictable errors.
These conventions keep the Bash and PowerShell runners maintainable even though
they are shipped as single files.

---

## General principles

1. **One responsibility per module.** If a function needs a name containing
   "and", it probably belongs in two modules.
2. **Keep the shipped runners dependency-free.** Do not add a runtime
   dependency for normal execution.
3. **Preserve exit codes.** A compiler or program status must pass through
   unchanged.
4. **Quote everything.** Paths may contain spaces or shell metacharacters.
5. **Comment the why, not the what.** The code says what it does; comments
   explain constraints, trade-offs, and non-obvious decisions.
6. **No dead code.** Remove unused helpers instead of leaving them around.
7. **Generated files are never edited.** Change `src/` and rebuild.

---

## Bash

### Formatting

- Four spaces, no tabs.
- Keep lines readable; wrap long pipelines with a trailing `\`.
- Put `local` declarations at the top of a function.
- Use `[ ... ]` for simple tests and `[[ ... ]]` when a regex or pattern match
  is clearer.
- Use `case` for multi-way dispatch.

### Functions

- Use `snake_case` names.
- Document non-obvious functions with a short comment block above them.
- Set `local` variables for everything that does not need to be shared.
- Return status explicitly with `return $?` when forwarding a command's status.
- Use `exit` only at the CLI boundary. Library-style helpers should return.

### Variables

- Constants and shared state are `UPPER_CASE` (`CODERUN_VERSION`,
  `LANG_ID`).
- Parser and runtime state is `lower_case` (`mode`, `file`, `runtime_opt`).
- Document any global that another module must read or write. The contract is
  listed at the top of `src/unix/95-cli.sh` and in
  [Architecture](architecture.md#shared-state).

### Quoting

Always quote expansions that become arguments:

```bash
"$file"
"$dir/$base"
"${program_args[@]}"
```

Use `"$@"` to forward all arguments. Do not use unquoted `$*`.

### Error handling

- Print errors to stdout, matching the existing user-facing messages.
- Return non-zero from helpers and let the caller decide whether to `exit`.
- Never mask a compiler or program exit code.
- Clean up temporary files with a trap (`cleanup_temp`).

### Portability

The Unix runner targets Bash 3.2:

- No associative arrays (`declare -A`).
- No namerefs (`declare -n`).
- No `mapfile`/`readarray`.
- No `${var,,}` lowercasing (use `tr`).
- Avoid `&>` redirection (use `>file 2>&1`).

Test with `bash -n` at minimum. CI runs ShellCheck.

Source modules are linted individually, so each begins with
`# shellcheck shell=bash`. A module that intentionally shares globals disables
only the relevant `SC2034` or `SC2154` check at the top of the file; keep those
suppressions narrow and rely on the shared-state contract in
[Architecture](architecture.md#shared-state).

---

## PowerShell

### Formatting

- Four spaces, no tabs.
- Opening braces on the same line for functions and control statements, with
  `else`/`catch`/`finally` on their own line (matching the existing file).
- Use `param()` blocks for every function parameter.
- Prefer `-LiteralPath` for filesystem cmdlets.

### Functions

- Use approved `Verb-Noun` names (`Show-Help`, `Invoke-Compile`). The analyzer
  settings allow a few project-specific exceptions.
- Return values explicitly. Use `return` for early exits.
- Keep script-wide state in `$script:` variables when a function assigns it.
- Do not use `Write-Host` for data output; it is for user-facing messages.
  Existing informational output uses `Write-Host` intentionally and the
  analyzer rule is disabled.

### Compatibility

Support Windows PowerShell 5.1 and PowerShell 7+:

- Avoid APIs introduced after 5.1 unless guarded.
- Use `[System.IO.Path]` helpers instead of string concatenation for paths.
- Keep `param()` as the first statement in the generated runner.

---

## Comments and documentation

- Every module starts with a banner: file name, responsibility, and any
  important contract.
- Add a short comment above functions that are not obvious.
- Explain invariants and platform differences, not syntax.
- Keep user-facing documentation in `README.md` and maintainer documentation
  in `docs/`.
- When behaviour changes, update the help text, README, and tests together.

---

## Tests

- Use the shared assertions in `tests/lib/`.
- Test observable behaviour: output, exit codes, and the shim log.
- Cover the failure path as well as the success path.
- Keep tests independent and order-insensitive.
- Use temporary directories under `TMPDIR` and clean them with a trap.

---

## Review checklist

Before opening a pull request:

- [ ] The change is in `src/`, not in a generated file.
- [ ] `./scripts/build.sh` has been run.
- [ ] `./scripts/check.sh` passes.
- [ ] Relevant test suites pass.
- [ ] Help text, README, and docs are updated when behaviour changes.
- [ ] `SHA256SUMS` is regenerated when a release file changed.
- [ ] New globals or module contracts are documented.
- [ ] Error messages follow the existing `Error: ...` style.
