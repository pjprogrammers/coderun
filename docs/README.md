# coderun documentation

This directory explains how coderun is built, tested, and released. Start with
the document that matches what you are trying to do.

| Document | Read it when you want to... |
| --- | --- |
| [Architecture](architecture.md) | Understand how the pieces fit together, how the single-file runners are produced, or where to add a language or command. |
| [Development](development.md) | Set up a checkout, build the runners, run tests, or find your way around the repository. |
| [Testing](testing.md) | Understand what the test suites cover and how the fake toolchains and update server work. |
| [Release](release.md) | Cut a release, update versions and checksums, or understand the published artifacts. |
| [Code style](code-style.md) | Match the project's Bash, PowerShell, and documentation conventions. |

If you only have five minutes, read
[Development](development.md#quick-start) and then run:

```bash
./scripts/build.sh
./scripts/check.sh
./tests/run-bash-tests.sh
```

The top-level [README](../README.md) is for users. These documents are for
maintainers and contributors.
