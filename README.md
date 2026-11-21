# coderun

**Run 26 programming languages with one command — on Linux, macOS, and Windows.**

[![Latest release](https://img.shields.io/github/v/release/pjprogrammers/coderun?label=release)](https://github.com/pjprogrammers/coderun/releases/latest)
[![Languages](https://img.shields.io/badge/languages-26-brightgreen)](#supported-languages)
[![Platforms](https://img.shields.io/badge/platforms-Linux%20%7C%20macOS%20%7C%20Windows-blue)](#supported-platforms)
[![License](https://img.shields.io/badge/license-MIT-yellow)](LICENSE)

`coderun` is a lightweight, cross-platform command-line runner. Give it a source file and it detects the language, uses the right compiler or runtime, compiles when needed, runs the program, and passes through the compiler or program exit code.

```bash
coderun main.cpp
coderun main.py
coderun --compile main.cpp
coderun --check
```

No build files, no configuration, no daemon.

---

## Contents

- [What is coderun?](#what-is-coderun)
- [Supported platforms](#supported-platforms)
- [Supported languages](#supported-languages)
- [Installation](#installation)
- [Quick start](#quick-start)
- [Command reference](#command-reference)
- [Build artifacts](#build-artifacts)
- [How it works](#how-it-works)
- [Requirements and toolchains](#requirements-and-toolchains)
- [Update and uninstall](#update-and-uninstall)
- [Exit codes](#exit-codes)
- [Project structure](#project-structure)
- [Development](#development)
- [Troubleshooting](#troubleshooting)
- [Versioning and releases](#versioning-and-releases)
- [Contributing](#contributing)
- [License](#license)

---

## What is coderun?

Different languages usually mean different commands:

| Without coderun | With coderun |
| --- | --- |
| `g++ main.cpp -o main && ./main` | `coderun main.cpp` |
| `gcc main.c -o main && ./main` | `coderun main.c` |
| `python3 main.py` | `coderun main.py` |
| `rustc main.rs -o main && ./main` | `coderun main.rs` |
| `java Main.java` | `coderun Main.java` |

`coderun` wraps those commands behind one consistent interface and keeps the behavior predictable across platforms.

### Features

- **26 languages** — 12 compiled and 14 interpreted.
- **3 platforms** — Linux, macOS, and Windows.
- **Program argument forwarding** — everything after the source file goes to the program unchanged.
- **Automatic compilation** for C, C++, Java, Rust, Go, Swift, Kotlin, Zig, Nim, Fortran, Pascal, and Crystal.
- **Direct execution** for Python, R, JavaScript, TypeScript, PHP, Ruby, Bash, Lua, Perl, Julia, Dart, Elixir, C#, and F#.
- **Runtime selection** with `--runtime node|bun|deno` for JavaScript and TypeScript.
- **Compile-only mode** with `--compile`.
- **Artifact cleanup** with `--clean`, including Java inner classes and Zig object files.
- **Custom output names** with `-o` / `--output`.
- **Friendly dependency checks** with `--check`, `--check <language>`, and `--check --strict`.
- **Language listing** with `--list` and install status with `--list --verbose`.
- **Shell completions** for Bash, Zsh, Fish, and PowerShell with `--completions`.
- **Timing and quiet output** with `--time` and `-q` / `--quiet`.
- **System information** with `--info`.
- **Update checking and self-update** with `--check-update` and `--update`.
- **Verified updates** — versioned downloads, embedded-version checks, and SHA-256 verification.
- **Uninstall with PATH cleanup** using `--uninstall`.
- **Exit-code preservation** — compiler and program exit codes are never masked.
- **Path-safe** — filenames with spaces and shell-special characters work.
- **Case-insensitive extensions** — `.PY`, `.Py`, and `.py` are equivalent.
- **No daemon, no configuration file, no build system.**

### At a glance

| | |
| --- | --- |
| **Current version** | 2.4.1 |
| **Languages** | 26 — 12 compiled, 14 interpreted |
| **Operating systems** | 3 — Linux, macOS, Windows |
| **Interface** | Command line |
| **Runner runtime** | Bash (Linux/macOS), PowerShell (Windows) |
| **License** | MIT |

---

## Supported platforms

| Platform | Runner | Installer | Installed location | C/C++ compiler |
| --- | --- | --- | --- | --- |
| Linux | `bin/coderun` | `install.sh` | `~/.local/bin/coderun` | `gcc` / `g++` |
| macOS | `bin/coderun-mac` | `install-mac.sh` | `~/.local/bin/coderun` | `clang` / `clang++` |
| Windows | `windows/coderun.ps1` | `install.ps1` | `%USERPROFILE%\bin\coderun.ps1` and `coderun.cmd` | `gcc` / `g++` |

The Bash runner is built from the modules in `src/unix/`; `scripts/build.sh` produces `bin/coderun` and the macOS copy `bin/coderun-mac`. The Windows runner is built from `src/windows/` into `windows/coderun.ps1`.

All three runners expose the same 26 languages and the same command-line options. The intentional platform differences are the C/C++ compiler choice, Python's executable name, and the shell integration.

---

## Supported languages

| Language | Extensions | Type | Default execution | Required tool(s) |
| --- | --- | --- | --- | --- |
| C | `.c` | Compiled | Compile, then run the binary | `gcc` (Linux/Windows), `clang` (macOS) |
| C++ | `.cpp` | Compiled | Compile, then run the binary | `g++` (Linux/Windows), `clang++` (macOS) |
| Python | `.py` | Interpreted | Run directly | `python3` (Linux/macOS), `python` (Windows) |
| R | `.R`, `.r` | Interpreted | Run with `Rscript` | `Rscript` |
| Java | `.java` | Compiled | `java Main.java` (source-file mode) | `java`, `javac` (Java 11+) |
| Rust | `.rs` | Compiled | Compile, then run the binary | `rustc` |
| JavaScript | `.js` | Interpreted | Run with `node` (override with `--runtime bun` or `--runtime deno`) | `node`, `bun`, or `deno` |
| TypeScript | `.ts` | Interpreted | Run with `tsx` (override with `--runtime node`, `bun`, or `deno`) | `tsx`, `node`, `bun`, or `deno` |
| Go | `.go` | Compiled | `go run` | `go` |
| PHP | `.php` | Interpreted | Run with `php` | `php` |
| Ruby | `.rb` | Interpreted | Run with `ruby` | `ruby` |
| Bash | `.sh` | Interpreted | Run with `bash` | `bash` |
| Swift | `.swift` | Compiled | `swift main.swift` (or `swiftc` with `--compile`) | `swift`, `swiftc` |
| Kotlin | `.kt` | Compiled | Compile to a JAR, then run with `java -jar` | `kotlinc`, `java` |
| Lua | `.lua` | Interpreted | Run directly | `lua` |
| Perl | `.pl` | Interpreted | Run directly | `perl` |
| Julia | `.jl` | Interpreted | Run directly | `julia` |
| Dart | `.dart` | Interpreted | Run with `dart run` | `dart` |
| Elixir | `.exs` | Interpreted | Run directly | `elixir` |
| Zig | `.zig` | Compiled | `zig run` (or `zig build-exe` with `--compile`) | `zig` |
| Nim | `.nim` | Compiled | `nim r` (or `nim c` with `--compile`) | `nim` |
| Fortran | `.f90`, `.f95`, `.f03`, `.f08`, `.for`, `.f` | Compiled | Compile, then run the binary | `gfortran` |
| Pascal | `.pas` | Compiled | Compile, then run the binary | `fpc` |
| Crystal | `.cr` | Compiled | `crystal run` (or `crystal build` with `--compile`) | `crystal` |
| C# | `.cs` | Interpreted | `dotnet run file.cs` (file-based apps, .NET 10+) | `dotnet` |
| F# | `.fsx`, `.fs` | Interpreted | `dotnet fsi` | `dotnet` |

Extensions are matched case-insensitively. Only the toolchains for the languages you actually use need to be installed. `.pl` is treated as Perl, and `.exs` as an Elixir script.

For JavaScript and TypeScript, `--runtime node|bun|deno` selects the runtime. JavaScript defaults to `node`; TypeScript defaults to `tsx` when no runtime is specified.

---

## Installation

### Prerequisites

Installation prerequisites:

| Platform | Prerequisites |
| --- | --- |
| Linux | Bash, `git` (clone only); recommended: `gcc`, `g++`, `python3` |
| macOS | Bash, `git` (clone only); recommended: Apple Command Line Tools (`clang`, `clang++`, `python3`) |
| Windows | PowerShell, `git` (clone only); recommended: `gcc`, `g++`, `python` on PATH |

`git` is only needed to clone the repository; you can also download the repository as a ZIP. The installer always installs `coderun` itself and prints warnings for missing baseline tools instead of failing. No language toolchain is required to install or update `coderun` — see [Requirements and toolchains](#requirements-and-toolchains). After installing, `coderun --check` shows what is ready.

All three installers are user-level and do not require administrator access for `coderun` itself. Installing language toolchains may require administrator access depending on the tool.

### Linux

```bash
git clone https://github.com/pjprogrammers/coderun.git
cd coderun
./install.sh
```

The installer:

- warns when `gcc`, `g++`, or `python3` are missing, but continues;
- copies the runner to `~/.local/bin/coderun`;
- adds `~/.local/bin` to `~/.bashrc` if needed;
- makes the command executable.

Open a new terminal after installation:

```bash
coderun --version
```

If you use Zsh, Fish, or another shell, add `~/.local/bin` to that shell's PATH manually.

### macOS

```bash
git clone https://github.com/pjprogrammers/coderun.git
cd coderun
./install-mac.sh
```

The installer:

- warns when `clang`, `clang++`, or `python3` are missing, but continues;
- copies the runner to `~/.local/bin/coderun`;
- adds the directory to `~/.zshrc`, or `~/.zprofile` when `.zshrc` does not exist;
- makes the command executable.

Open a new terminal after installation:

```bash
coderun --version
```

The macOS installer configures Zsh by default. If you use another shell, add `~/.local/bin` to that shell's PATH manually.

### Windows

Open PowerShell in the repository directory:

```powershell
git clone https://github.com/pjprogrammers/coderun.git
cd coderun
.\install.ps1
```

Command Prompt users can run the wrapper, which invokes the same installer with the execution policy bypassed:

```cmd
install.cmd
```

If PowerShell blocks the script, run:

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

The installer:

- warns when `gcc`, `g++`, or `python` are missing, but continues;
- copies the runner to `%USERPROFILE%\bin\coderun.ps1`;
- creates `%USERPROFILE%\bin\coderun.cmd` so `coderun` works from PowerShell and Command Prompt;
- adds `%USERPROFILE%\bin` to the User PATH.

Open a new terminal after installation:

```powershell
coderun --version
```

### Verify the installation

```bash
coderun --version
coderun --info
coderun --check
```

`--check` is the quickest way to see which language toolchains are available. It is informational and exits `0`. Use `coderun --check <language>` to require one toolchain, or `coderun --check --strict` in CI to fail when anything is missing.

---

## Quick start

Create `main.cpp`:

```cpp
#include <iostream>

int main() {
    std::cout << "Hello from coderun!\n";
    return 0;
}
```

Run it:

```bash
coderun main.cpp
```

```text
Hello from coderun!
```

Common commands:

```bash
coderun main.py                    # run an interpreted file
coderun main.py --verbose          # pass --verbose to the program
coderun main.cpp input.txt         # pass input.txt to the program
coderun --compile main.cpp         # compile without running
coderun -o app main.cpp            # compile to ./app and run it
coderun --clean main.cpp           # remove the default artifact
coderun --clean -o app main.cpp    # remove the custom and default artifacts
coderun --runtime bun app.ts       # run TypeScript with Bun
coderun --time main.py             # report elapsed time
coderun --list                     # list supported languages
coderun --list --verbose           # show which toolchains are installed
coderun --check                    # check installed toolchains (exit 0)
coderun --check python             # require Python (exit 1 if missing)
coderun --check --strict           # fail if any toolchain is missing
coderun --completions bash         # print Bash completions
```

### Run any supported language

```bash
coderun main.c          # C
coderun main.cpp        # C++
coderun main.py         # Python
coderun analysis.R      # R
coderun Main.java       # Java
coderun main.rs         # Rust
coderun app.js          # JavaScript
coderun app.ts          # TypeScript
coderun main.go         # Go
coderun index.php       # PHP
coderun script.rb       # Ruby
coderun script.sh       # Bash
coderun main.swift      # Swift
coderun Main.kt         # Kotlin
coderun main.lua        # Lua
coderun script.pl       # Perl
coderun analysis.jl     # Julia
coderun main.dart       # Dart
coderun script.exs      # Elixir
coderun main.zig        # Zig
coderun main.nim        # Nim
coderun main.f90        # Fortran
coderun main.pas        # Pascal
coderun main.cr         # Crystal
coderun Program.cs      # C#
coderun script.fsx      # F#
```

---

## Command reference

| Command | Description |
| --- | --- |
| `coderun <file> [args...]` | Detect the language, compile if necessary, run the file, and pass the remaining arguments to the program. |
| `coderun --compile <file>` | Compile only; the program is not executed. |
| `coderun --clean <file>` | Remove generated artifacts for the file. |
| `coderun -o <name> <file> [args...]` | Compile to a custom artifact, run it, and pass the remaining arguments to the program. |
| `coderun --output <name> <file> [args...]` | Long form of `-o`. |
| `coderun --runtime <name> <file> [args...]` | Use `node`, `bun`, or `deno` for JavaScript/TypeScript. |
| `coderun --time <file> [args...]` | Run or compile and report elapsed time on stderr. |
| `coderun -q <file>`, `coderun --quiet <file>` | Suppress coderun's own informational messages. |
| `coderun --list` | List supported languages, extensions, and types. |
| `coderun --list --verbose` | List languages and whether their tools are installed. |
| `coderun --check` | Check required compilers and runtimes (always exits `0`). |
| `coderun --check <language>` | Check one toolchain; exits `1` if it is missing. |
| `coderun --check --strict` | Check everything; exits `1` if any toolchain is missing. |
| `coderun --completions <shell>` | Print completions for `bash`, `zsh`, `fish`, or `powershell`. |
| `coderun --info` | Show version, install path, OS, architecture, and shell/PowerShell. |
| `coderun --check-update` | Check for a newer release. |
| `coderun --update` | Update the installed runner. |
| `coderun --uninstall` | Remove the installed runner and its PATH entry. |
| `coderun -h`, `coderun --help` | Show help. |
| `coderun -v`, `coderun --version` | Show the installed version. |

Notes:

- Everything after `<file>` is forwarded to the program unchanged. One immediate `--` separator after the file is dropped, so `coderun main.py -- --flag` passes `--flag`.
- Use `coderun -- -file.py` when the filename itself begins with `-`.
- `--compile` and `--clean` cannot be combined, and neither accepts program arguments.
- `--compile` works for compiled languages. Interpreted languages return an unsupported-operation error.
- `-o` / `--output` works for C, C++, Rust, Go, Swift, Kotlin, Zig, Nim, Fortran, Pascal, and Crystal. It is not supported for Java or interpreted languages.
- `--runtime` is only supported for JavaScript and TypeScript, and its value must be `node`, `bun`, or `deno`.
- The output path must not be the source file itself.

### Help and version

```bash
coderun --help
coderun --version
```

`--help` prints usage, grouped options, supported languages, and examples. `--version` prints `coderun <version>`.

### Language and environment information

```bash
coderun --list
coderun --list --verbose
coderun --check
coderun --check python
coderun --check --strict
coderun --info
```

- `--list` prints all 26 languages with their extensions and whether they are compiled or interpreted.
- `--list --verbose` also prints whether each language's tools are installed.
- `--check` prints every language's status and exits `0`, even when tools are missing.
- `--check <language>` exits `1` when that language's tools are missing. It accepts names (`python`), IDs (`py`), extensions (`.py`), aliases (`golang`, `js`, `ts`, `cxx`), or tool names (`gcc` on Linux/Windows, `clang` on macOS, `node`).
- `--check --strict` exits `1` when any toolchain is missing, which is useful in CI.
- `--info` prints the version, install path, operating system, architecture, and shell (PowerShell version on Windows).

### Compile, clean, and custom output

```bash
coderun --compile main.cpp
coderun --clean main.cpp
coderun -o app main.cpp
coderun --output build/app main.cpp
coderun -o app main.cpp --port 8080
```

`--compile` writes the artifact and reports the artifact location without running it. `--clean` removes artifacts. `-o` chooses a custom artifact name and runs the result in normal execution mode, forwarding any arguments after the source file.

---

## Build artifacts

### Default artifacts

| Language | Linux/macOS | Windows | Notes |
| --- | --- | --- | --- |
| C | `<name>` | `<name>.exe` | Beside the source file |
| C++ | `<name>` | `<name>.exe` | Beside the source file |
| Rust | `<name>` | `<name>.exe` | Beside the source file |
| Go | none (`go run`) | none (`go run`) | `--compile` or `-o` creates `<name>` / `<name>.exe` |
| Swift | none (`swift`) | none (`swift`) | `--compile` or `-o` creates `<name>` / `<name>.exe` |
| Kotlin | `<name>.jar` | `<name>.jar` | Run with `java -jar` |
| Java | `<name>.class` + inner classes with `--compile` | same | Default run uses `java File.java` |
| Zig | none (`zig run`) | none (`zig run`) | `--compile` creates `<name>` / `<name>.exe` and `<name>.o` |
| Nim | none (`nim r`) | none (`nim r`) | `--compile` or `-o` creates `<name>` / `<name>.exe` |
| Fortran | `<name>` | `<name>.exe` | Beside the source file |
| Pascal | `<name>` | `<name>.exe` | Beside the source file |
| Crystal | none (`crystal run`) | none (`crystal run`) | `--compile` or `-o` creates `<name>` / `<name>.exe` |
| Python, R, JavaScript, TypeScript, PHP, Ruby, Bash, Lua, Perl, Julia, Dart, Elixir, C#, F# | none | none | No build step |

For example, `main.cpp` becomes `main` on Linux/macOS and `main.exe` on Windows.

### Custom output with `-o` / `--output`

```bash
coderun -o app main.cpp
coderun --output build/app main.cpp
```

Rules:

- Supported for C, C++, Rust, Go, Swift, Kotlin, Zig, Nim, Fortran, Pascal, and Crystal.
- Not supported for Java or interpreted languages.
- Relative paths are resolved from the current directory.
- If the name already has an extension, it is used as-is.
- On Windows, `.exe` is appended when a non-Kotlin output has no extension.
- Kotlin appends `.jar` when the output has no extension, on every platform.
- The output path cannot be the source file.

In normal run mode, `coderun -o app main.cpp` compiles to `app` (or `app.exe` on Windows) and runs that artifact. With `--compile`, it only creates the artifact.

### Cleaning artifacts

```bash
coderun --clean main.cpp
coderun --clean -o app main.cpp
```

`--clean`:

- removes the default artifact for the source file, if present;
- also removes the custom `-o` artifact when one is supplied;
- removes Zig object files (`<name>.o`) alongside the binary;
- removes Java class files matching the source name, including inner classes, in the source directory;
- reports when an interpreted language has nothing to clean;
- exits `0` when the clean completes, even if there was nothing to remove;
- exits `1` for validation or removal failures.

---

## How it works

```text
coderun main.cpp input.txt
      │
      ├─ 1. Parse coderun options until the source file
      ├─ 2. Read the file extension (.cpp)
      ├─ 3. Treat everything after the file as program arguments
      ├─ 4. Select the platform compiler (g++ / clang++ / g++)
      ├─ 5. Compile to an artifact
      ├─ 6. Run the artifact with the program arguments
      └─ 7. Exit with the program's exit code
```

For interpreted files, compilation becomes a single interpreter call:

```text
coderun app.py --verbose
      └─ python3 app.py --verbose → exit with the program's exit code
```

Coderun's own options are only recognized before the source file. After the file, `--list`, `--quiet`, and every other flag belong to the program. A single `--` immediately after the file is treated as a separator and is not passed on.

### Compiler selection

| Platform | C | C++ |
| --- | --- | --- |
| Linux | `gcc` | `g++` |
| macOS | `clang` | `clang++` |
| Windows | `gcc` | `g++` |

The other runtimes use the same tool names on every platform, except Python: `python3` on Linux/macOS and `python` on Windows.

The module layout, shared state, and update security model are documented in [docs/architecture.md](docs/architecture.md).

---

## Requirements and toolchains

### coderun itself

| Platform | Requirements |
| --- | --- |
| Linux | Bash; `curl` or `wget` plus `sha256sum` or `shasum` for `--update` and `--check-update` |
| macOS | Bash 3.2 or newer; `curl` or `wget` plus `shasum` for `--update` and `--check-update` |
| Windows | PowerShell (`--update` and `--check-update` use the built-in `Invoke-WebRequest` and `Get-FileHash`) |

No language toolchain is bundled with `coderun`. Install the tools for the languages you use and make sure they are on PATH. The [Supported languages](#supported-languages) table lists the exact tool names.

<details>
<summary><strong>Where to get each toolchain</strong></summary>

| Tool | Used for | Where to get it |
| --- | --- | --- |
| `gcc`, `g++` | C and C++ on Linux/Windows | GCC, MinGW-w64, or MSYS2 |
| `clang`, `clang++` | C and C++ on macOS | `xcode-select --install` |
| `python3` / `python` | Python | https://www.python.org/downloads/ |
| `Rscript` | R | https://cran.r-project.org/ |
| `java` | Running Java and Kotlin JARs | https://adoptium.net/ (Java 11+) |
| `javac` | Compiling `.java` files with `--compile` | Included with the JDK |
| `rustc` | Rust | https://rustup.rs/ |
| `node` | JavaScript and TypeScript | https://nodejs.org/ |
| `tsx` | TypeScript (default runtime) | `npm install -g tsx` |
| `bun` | JavaScript and TypeScript via `--runtime bun` | https://bun.sh/ |
| `deno` | JavaScript and TypeScript via `--runtime deno` | https://deno.com/ |
| `go` | Go | https://go.dev/dl/ |
| `php` | PHP | https://www.php.net/downloads |
| `ruby` | Ruby | https://www.ruby-lang.org/en/downloads/ |
| `bash` | Bash | Built in on Linux/macOS; Git Bash, WSL, or MSYS2 on Windows |
| `swift`, `swiftc` | Swift | https://www.swift.org/install/ |
| `kotlinc` | Kotlin | https://kotlinlang.org/docs/command-line.html |
| `lua` | Lua | https://www.lua.org/download.html |
| `perl` | Perl | https://www.perl.org/get.html |
| `julia` | Julia | https://julialang.org/downloads/ |
| `dart` | Dart | https://dart.dev/get-dart |
| `elixir` | Elixir | https://elixir-lang.org/install.html |
| `zig` | Zig | https://ziglang.org/download/ |
| `nim` | Nim | https://nim-lang.org/install.html |
| `gfortran` | Fortran | GCC's Fortran front end; on Ubuntu/Debian: `sudo apt install gfortran` |
| `fpc` | Pascal | https://www.freepascal.org/download.html |
| `crystal` | Crystal | https://crystal-lang.org/install/ |
| `dotnet` | C# and F# | https://dotnet.microsoft.com/download (C# file-based apps require .NET 10+) |

</details>

Use `coderun --check <language>` to verify one toolchain, or `coderun --check --strict` to require every toolchain (for example in CI).

---

## Update and uninstall

### Upgrading from V1.0.0 or V2.0.0

`--version` and `--update` were introduced in V2.1.0. Earlier versions do not parse flags at all, so `coderun --update` is treated as a filename and fails with `Error: file not found: --update`.

Upgrade once manually, then use `coderun --update` for every later release.

**If the repository clone still exists:**

```bash
cd coderun
git pull
./install.sh        # Linux
./install-mac.sh    # macOS
```

```powershell
cd coderun
git pull
.\install.ps1       # Windows
```

**If the clone is gone,** download the current runner directly:

```bash
# Linux
curl -fsSL https://raw.githubusercontent.com/pjprogrammers/coderun/main/bin/coderun \
  -o ~/.local/bin/coderun
chmod +x ~/.local/bin/coderun

# macOS
curl -fsSL https://raw.githubusercontent.com/pjprogrammers/coderun/main/bin/coderun-mac \
  -o ~/.local/bin/coderun
chmod +x ~/.local/bin/coderun
```

```powershell
# Windows
Invoke-WebRequest `
  -Uri https://raw.githubusercontent.com/pjprogrammers/coderun/main/windows/coderun.ps1 `
  -OutFile "$env:USERPROFILE\bin\coderun.ps1"
```

Confirm the upgrade:

```bash
coderun --version
# coderun 2.4.0
```

The installers replace the existing runner file and keep the existing PATH entry. On Linux/macOS, use `which -a coderun` to check for an older copy earlier in PATH; on Windows, use `Get-Command coderun -All`.

### Check for updates

```bash
coderun --check-update
```

`--check-update` reads the published `VERSION` file and compares it with the installed version.

- Exit `0`: the installed version is current or newer.
- Exit `1`: a newer version is available, or the check failed.

This is a check only; it does not change anything.

### Update

```bash
coderun --update
```

`--update` checks the published version before downloading anything:

- If the installed version is current, it reports `coderun is up to date (<version>).` and exits `0` without replacing the installed runner.
- If a newer version is available, it downloads the platform-specific runner, verifies it, replaces the installed copy atomically, and reports the new version.

`--update` requires V2.1.0 or newer; older versions must upgrade once using the installer or a manual download. See [Upgrading from V1.0.0 or V2.0.0](#upgrading-from-v100-or-v200).

- Linux/macOS: requires `curl` or `wget` and `sha256sum` or `shasum`.
- Windows: uses PowerShell's `Invoke-WebRequest` and `Get-FileHash`.
- The runner must already be installed in the standard location.
- Downloads come from the versioned tag (`/v<version>/...`), not from `main`.
- The downloaded runner must have the expected first line (`#!/usr/bin/env bash` on Linux/macOS, `param(` on Windows) and a `CODERUN_VERSION` matching the announced release.
- `SHA256SUMS` from the same tag is verified before the installed runner is replaced.
- Replacement uses a temporary file and an atomic move. A failed version check, download, version check, or checksum leaves the installed runner unchanged.
- V2.3.1 installs can update to V2.4.0 with their existing updater; the 2.3.1 updater still uses the compatible `/main/` URL and shebang check.

`CODERUN_RAW_BASE` overrides the raw GitHub base URL for mirrors and automated tests:

```bash
CODERUN_RAW_BASE=https://mirror.example.com/coderun coderun --update
```

### Uninstall

```bash
coderun --uninstall
```

`--uninstall` removes the installed runner and cleans up its PATH entry when the install directory is left empty.

- Linux/macOS: removes `~/.local/bin/coderun`; if `~/.local/bin` is empty, removes the PATH entry and the directory.
- Windows: removes `coderun.ps1` and `coderun.cmd`; if `%USERPROFILE%\bin` has no other files, removes it from the User PATH and deletes the directory.
- If the install directory contains other tools, the directory and its PATH entry are preserved.

Open a new terminal after uninstalling.

---

## Exit codes

| Exit code | Meaning |
| --- | --- |
| `0` | Success. |
| `1` | Usage error, missing file, unsupported type, missing dependency, failed update/check, or an unsupported `--compile`/`-o` request. |
| other | The compiler's or program's exit code is passed through unchanged. |

Specific cases:

- `coderun --check`: always `0` for a completed informational check.
- `coderun --check <language>`: `1` if that language's tools are missing or the language is unknown.
- `coderun --check --strict`: `1` if any toolchain is missing.
- `coderun --check-update`: `1` if a newer release exists or the check fails.
- `coderun --update`: `1` on a failed version check, download, version check, or checksum verification.
- `coderun --compile`: the compiler's exit code on failure, `0` on success.
- `coderun <file>`: the compiler's exit code if compilation fails, otherwise the program's exit code.
- Program arguments do not change exit-code behavior; the program's code is still passed through.

---

## Project structure

```text
coderun/
├── src/
│   ├── unix/
│   │   ├── 10-config.sh      # Version, paths, platform detection
│   │   ├── 20-output.sh      # Logging and timing helpers
│   │   ├── 30-languages.sh   # Language registry and dependency checks
│   │   ├── 40-help.sh        # --help text
│   │   ├── 50-completions.sh # Shell completions
│   │   ├── 60-info.sh        # --info
│   │   ├── 70-update.sh      # Update, version check, uninstall
│   │   ├── 80-compile.sh     # Compile and clean
│   │   ├── 90-run.sh         # Run dispatch
│   │   ├── 95-cli.sh         # Parsing, validation, and main flow
│   │   └── 99-main.sh        # Entry point
│   └── windows/
│       ├── 00-header.ps1     # Parameters, version, configuration
│       ├── 10-languages.ps1  # Language registry and checks
│       ├── 20-output.ps1     # Informational output and help
│       ├── 30-completions.ps1
│       ├── 40-info.ps1
│       ├── 50-update.ps1
│       ├── 60-execution.ps1  # Compile and clean
│       └── 70-cli.ps1        # Parsing, validation, and run dispatch
├── bin/
│   ├── coderun          # Generated Linux/macOS runner
│   └── coderun-mac      # Generated macOS copy
├── windows/
│   └── coderun.ps1      # Generated Windows runner
├── scripts/
│   ├── build.sh         # Build the runners from src/
│   ├── checksums.sh     # Generate SHA256SUMS
│   ├── check.sh         # Consistency, syntax, and hash checks
│   └── release.sh       # Version bump, tag, and GitHub release
├── tests/
│   ├── lib/
│   │   ├── assertions.sh
│   │   └── hash.sh
│   ├── run-bash-tests.sh
│   ├── update-bash-tests.sh
│   ├── installer-tests.sh
│   ├── run-powershell-tests.ps1
│   ├── installer-tests.ps1
│   └── fake-tool.sh
├── docs/
│   ├── README.md
│   ├── architecture.md
│   ├── development.md
│   ├── testing.md
│   ├── release.md
│   └── code-style.md
├── .github/
│   ├── workflows/ci.yml
│   └── PSScriptAnalyzerSettings.psd1
├── install.sh           # Linux installer
├── install-mac.sh       # macOS installer
├── install.ps1          # Windows installer
├── install.cmd          # Command Prompt wrapper for install.ps1
├── VERSION              # Release version (2.4.1)
├── SHA256SUMS           # Checksums for release files
├── Makefile             # Common developer tasks
├── CONTRIBUTING.md      # Contributor guide
├── .editorconfig        # Editor defaults
├── .gitignore           # Ignored local files
├── README.md
└── LICENSE
```

| Path | Purpose |
| --- | --- |
| `src/unix/` | Modular source for the Bash runner (Linux and macOS) |
| `src/windows/` | Modular source for the PowerShell runner (Windows) |
| `bin/coderun` | Generated unified Bash runner for Linux and macOS |
| `bin/coderun-mac` | Generated macOS copy, kept for compatibility |
| `windows/coderun.ps1` | Generated PowerShell runner for Windows |
| `scripts/build.sh` | Concatenates `src/` modules into the single-file runners |
| `scripts/checksums.sh` | Regenerates `SHA256SUMS` |
| `scripts/check.sh` | Verifies version consistency, generated files, file modes, syntax, and checksums |
| `scripts/release.sh` | Bumps versions, rebuilds runners, tags, pushes, and creates a GitHub release |
| `tests/run-bash-tests.sh` | Unix behavior tests (languages, arguments, flags, output) |
| `tests/update-bash-tests.sh` | Unix update and checksum tests against a local HTTP server |
| `tests/installer-tests.sh` | Unix installer tests with temporary `HOME` values |
| `tests/run-powershell-tests.ps1` | Windows behavior and update tests |
| `tests/installer-tests.ps1` | Windows installer tests with temporary `USERPROFILE` values |
| `tests/fake-tool.sh` | Fake toolchain shim used by Unix tests |
| `tests/lib/` | Shared assertions and hashing helpers |
| `docs/` | Maintainer documentation: architecture, development, testing, release, and style |
| `.github/workflows/ci.yml` | Linux, macOS, and Windows CI matrix |
| `.github/PSScriptAnalyzerSettings.psd1` | PSScriptAnalyzer rules for the Windows runner |
| `install.sh` | Installs the runner to `~/.local/bin` on Linux |
| `install-mac.sh` | Installs the runner to `~/.local/bin` on macOS |
| `install.ps1` | Installs the runner to `%USERPROFILE%\bin` on Windows |
| `install.cmd` | Command Prompt wrapper for `install.ps1` |
| `VERSION` | Single tracked release version, mirrored in the runners |
| `SHA256SUMS` | Release checksums verified by `--update` |
| `Makefile` | Shortcuts for build, check, test, and lint |
| `CONTRIBUTING.md` | Contributor workflow and pull request checklist |
| `README.md` | User documentation |
| `LICENSE` | MIT license |

---

## Development

The committed runners are generated from `src/`. Users never need to build anything, but maintainers edit the modules and regenerate the artifacts:

```bash
./scripts/build.sh      # regenerate bin/coderun, bin/coderun-mac, and windows/coderun.ps1
./scripts/check.sh      # verify versions, generated files, syntax, and checksums
```

Common tasks are also available through `make`:

```bash
make build
make check
make test
```

See [`docs/`](docs/README.md) for the architecture, development workflow, testing strategy, release process, and code style. Contributions are welcome; start with [CONTRIBUTING.md](CONTRIBUTING.md).

### Source layout

- `src/unix/` contains the Bash runner modules.
- `src/windows/` contains the PowerShell runner modules.
- Generated files are marked with a `GENERATED FILE - DO NOT EDIT` banner.
- `scripts/build.sh --check` fails when a generated file is stale.

The design and module responsibilities are documented in [docs/architecture.md](docs/architecture.md).

---

## Troubleshooting

| Problem | Fix |
| --- | --- |
| `coderun: command not found` | Open a new terminal. Confirm `~/.local/bin` (Linux/macOS) or `%USERPROFILE%\bin` (Windows) is on PATH. |
| Installer warns that `gcc`/`g++` is missing | The install still succeeded. Install a C/C++ toolchain when you need C or C++. On Ubuntu/Debian: `sudo apt install build-essential`. On Windows: MinGW-w64 or MSYS2. |
| Installer warns that `clang` is missing on macOS | The install still succeeded. Run `xcode-select --install` when you need C or C++. |
| `--check` reports missing tools | Install the toolchain for the language you need, or ignore languages you do not use. Use `--check --strict` in CI. |
| `tsx` not found | Install Node.js, then run `npm install -g tsx`. Or use `--runtime node`, `--runtime bun`, or `--runtime deno` when supported. |
| Zig, Nim, Fortran, Pascal, or Crystal is not found | Install the matching toolchain and ensure it is on PATH. See [Requirements and toolchains](#requirements-and-toolchains). |
| C# file-based app does not run | Install the .NET 10 SDK or newer and make sure `dotnet` is on PATH. |
| A `.java` file does not run | Use Java 11 or newer for source-file execution. Check with `java -version`. |
| Kotlin does not run | Ensure both `kotlinc` and `java` are on PATH. |
| `bash` not found on Windows | Install Git Bash, WSL, or MSYS2 and add `bash` to PATH. |
| PowerShell blocks `install.ps1` | Run `powershell -ExecutionPolicy Bypass -File .\install.ps1`. |
| `--check-update` exits `1` | `1` means a newer release is available or the check failed. Read the message. |
| `--update` fails | Check your network connection and, on Linux/macOS, that `curl` or `wget` and `sha256sum` or `shasum` are installed. |
| `update checksum verification failed` | The download did not match the published `SHA256SUMS`. Nothing was replaced; retry the update. If it persists, report the release. |
| Program flags are rejected before the file | Put coderun options before the source file. Everything after `<file>` is forwarded to the program. |
| Permission denied running an installer | Run `chmod +x install.sh` or `chmod +x install-mac.sh`. |
| Custom output path is missing | Create the parent directory before compiling, for example `mkdir -p build`. |

---

## Versioning and releases

`coderun` follows [Semantic Versioning](https://semver.org/):

| Component | Meaning |
| --- | --- |
| MAJOR | Incompatible changes to the command or its behavior |
| MINOR | New, backward-compatible features |
| PATCH | Backward-compatible bug fixes |

The release version is tracked in [`VERSION`](VERSION) and mirrored in the Linux, macOS, and Windows runners. `coderun --version` prints the installed runner's version.

### Current release: V2.4.1

V2.4.0 is the largest release since the project moved to a multi-language runner:

- **Program arguments are forwarded.** `coderun main.py --verbose` and `coderun main.cpp input.txt` now work. Everything after the source file belongs to the program; `--compile`, `--clean`, `-o`, and coderun's other options only apply before the file.
- **Seven new languages:** Zig, Nim, Fortran, Pascal, Crystal, C# (file-based apps), and F# scripts. The total is now 26 languages: 12 compiled and 14 interpreted.
- **Runtime selection:** `--runtime node|bun|deno` for JavaScript and TypeScript.
- **Friendlier checks:** `--check` is informational and exits `0`; `--check <language>` requires one toolchain; `--check --strict` fails when anything is missing.
- **Installers are decoupled:** `install.sh`, `install-mac.sh`, and `install.ps1` install the runner unconditionally and warn about missing baseline tools.
- **Verbose listing:** `--list --verbose` shows whether each language's tools are installed.
- **Shell completions:** `--completions bash|zsh|fish|powershell`.
- **Output controls:** `--time` reports elapsed time on stderr; `-q` / `--quiet` suppresses coderun's own messages.
- **Hardened updates:** downloads come from the versioned tag, the runner's embedded version must match the announced release, `SHA256SUMS` is verified, and replacement stays atomic.
- **One Unix runner:** Linux and macOS now share `bin/coderun`; `bin/coderun-mac` is a generated copy kept for compatibility with the macOS installer and updater.
- **Table-driven language metadata:** adding a language no longer requires editing a dozen dispatch blocks in each runner.
- **Real tests and CI:** Unix and Windows suites cover every language with fake toolchains, update security cases, and installer behavior. CI runs on Ubuntu, macOS, and Windows, including PowerShell 7 and Windows PowerShell 5.1.

V2.3.1 made `--update` version-aware and added `install.cmd`. V2.3.0 added Lua, Perl, Julia, Dart, and Elixir; see the release history below.

### Release history

| Version | Release | Highlights |
| --- | --- | --- |
| V1.0.0 | [v1.0.0](https://github.com/pjprogrammers/coderun/releases/tag/v1.0.0) | Initial release with C, C++, and Python support |
| V2.0.0 | [v2.0.0](https://github.com/pjprogrammers/coderun/releases/tag/v2.0.0) | Expanded to 14 languages |
| V2.1.0 | [v2.1.0](https://github.com/pjprogrammers/coderun/releases/tag/v2.1.0) | Added help, version, update, and uninstall flags |
| V2.2.0 | [v2.2.0](https://github.com/pjprogrammers/coderun/releases/tag/v2.2.0) | Added list, check, info, check-update, compile, clean, and output options |
| V2.3.0 | [v2.3.0](https://github.com/pjprogrammers/coderun/releases/tag/v2.3.0) | Added Lua, Perl, Julia, Dart, and Elixir |
| V2.3.1 | [v2.3.1](https://github.com/pjprogrammers/coderun/releases/tag/v2.3.1) | Made `--update` version-aware and added a Command Prompt installer |
| V2.4.0 | [v2.4.0](https://github.com/pjprogrammers/coderun/releases/tag/v2.4.0) | Argument forwarding, 7 new languages, runtime selection, verified updates, unified Unix runner, and CI |

### Release process

1. Update `README.md` and run `scripts/check.sh`.
2. Run the Unix and PowerShell test suites.
3. Use `scripts/release.sh <version> --notes <file>` to bump the versions, rebuild the runners, regenerate `SHA256SUMS`, commit, tag, push, and create the GitHub release.
4. CI verifies the release on Ubuntu, macOS, and Windows.

See [docs/release.md](docs/release.md) for the complete release checklist.

---

## Contributing

1. Fork the repository.
2. Create a branch for your change.
3. For Linux/macOS behavior, edit the modules in `src/unix/`. For Windows behavior, edit `src/windows/`.
4. Regenerate the single-file runners with `./scripts/build.sh`.
5. Keep the runner versions and `VERSION` in sync, then run `./scripts/check.sh`.
6. Run the relevant tests:

   ```bash
   ./tests/run-bash-tests.sh
   ./tests/update-bash-tests.sh
   ./tests/installer-tests.sh
   pwsh -NoProfile -File tests/run-powershell-tests.ps1
   pwsh -NoProfile -File tests/installer-tests.ps1
   ```

   On Linux, `CODERUN_TEST_OS=Darwin ./tests/run-bash-tests.sh` simulates the macOS compiler selection.

7. Run ShellCheck on the Unix scripts and PSScriptAnalyzer on the Windows runner if they are available:

   ```bash
   shellcheck -S warning bin/coderun install.sh install-mac.sh scripts/*.sh src/unix/*.sh tests/*.sh tests/lib/*.sh
   ```

8. Add or update tests for behavior changes, including argument forwarding, exit codes, and paths with spaces.
9. Regenerate `SHA256SUMS` with `./scripts/checksums.sh` before committing release files.
10. Open a pull request describing the change and the platform you tested.

The committed runners are the product; users never need to build anything. Maintainers edit `src/` and run `./scripts/build.sh` to regenerate them. GitHub Actions runs the same checks on Ubuntu, macOS, and Windows. See [`CONTRIBUTING.md`](CONTRIBUTING.md) and [`docs/`](docs/README.md) for the full workflow.

---

## License

MIT. See [LICENSE](LICENSE).
