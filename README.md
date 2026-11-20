# coderun

**Run 19 programming languages with one command — on Linux, macOS, and Windows.**

[![Latest release](https://img.shields.io/github/v/release/pjprogrammers/coderun?label=release)](https://github.com/pjprogrammers/coderun/releases/latest)
[![Languages](https://img.shields.io/badge/languages-19-brightgreen)](#supported-languages)
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

- **19 languages** — 7 compiled and 12 interpreted.
- **3 platforms** — Linux, macOS, and Windows.
- **Automatic compilation** for C, C++, Java, Rust, Go, Swift, and Kotlin.
- **Direct execution** for Python, R, JavaScript, TypeScript, PHP, Ruby, Bash, Lua, Perl, Julia, Dart, and Elixir.
- **Compile-only mode** with `--compile`.
- **Artifact cleanup** with `--clean`, including Java inner classes.
- **Custom output names** with `-o` / `--output`.
- **Dependency checks** with `--check`.
- **Language listing** with `--list`.
- **System information** with `--info`.
- **Update checking and self-update** with `--check-update` and `--update`.
- **Uninstall with PATH cleanup** using `--uninstall`.
- **Exit-code preservation** — compiler and program exit codes are never masked.
- **Path-safe** — filenames with spaces and shell-special characters work.
- **Case-insensitive extensions** — `.PY`, `.Py`, and `.py` are equivalent.
- **No daemon, no configuration file, no build system.**

### At a glance

| | |
| --- | --- |
| **Current version** | 2.3.1 |
| **Languages** | 19 — 7 compiled, 12 interpreted |
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

All three runners expose the same 19 languages and the same command-line options. The intentional platform differences are the C/C++ compiler choice and the shell integration.

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
| JavaScript | `.js` | Interpreted | Run with `node` | `node` |
| TypeScript | `.ts` | Interpreted | Run with `tsx` | `tsx` |
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

Extensions are matched case-insensitively. Only the toolchains for the languages you actually use need to be installed. `.pl` is treated as Perl, and `.exs` as an Elixir script.

---

## Installation

### Prerequisites

Installation prerequisites:

| Platform | Prerequisites |
| --- | --- |
| Linux | Bash, `git`, `gcc`, `g++`, `python3` |
| macOS | Bash, `git`, Apple Command Line Tools (`clang`, `clang++`, `python3`) |
| Windows | PowerShell, `git`, `gcc`, `g++`, `python` on PATH |

`git` is only needed to clone the repository; you can also download the repository as a ZIP. The installer installs the `coderun` command itself and checks a small baseline of tools, but it does not install every language toolchain — see [Requirements and toolchains](#requirements-and-toolchains). After installing, `coderun --check` shows what is ready.

All three installers are user-level and do not require administrator access for `coderun` itself. Installing language toolchains may require administrator access depending on the tool.

### Linux

```bash
git clone https://github.com/pjprogrammers/coderun.git
cd coderun
./install.sh
```

The installer:

- verifies `gcc`, `g++`, and `python3`;
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

- verifies `clang`, `clang++`, and `python3`;
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

- verifies `gcc`, `g++`, and `python`;
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

`--check` is the quickest way to see which language toolchains are available. Missing optional toolchains only affect the languages that need them.

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
coderun --compile main.cpp         # compile without running
coderun -o app main.cpp            # compile to ./app and run it
coderun --clean main.cpp           # remove the default artifact
coderun --clean -o app main.cpp    # remove the custom and default artifacts
coderun --list                     # list supported languages
coderun --check                    # check installed toolchains
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
```

---

## Command reference

| Command | Description |
| --- | --- |
| `coderun <file>` | Detect the language, compile if necessary, and run the file. |
| `coderun --compile <file>` | Compile only; the program is not executed. |
| `coderun --clean <file>` | Remove generated artifacts for the file. |
| `coderun -o <name> <file>` | Compile to a custom artifact and run it. |
| `coderun --output <name> <file>` | Long form of `-o`. |
| `coderun --list` | List supported languages, extensions, and types. |
| `coderun --check` | Check required compilers and runtimes. |
| `coderun --info` | Show version, install path, OS, architecture, and shell/PowerShell. |
| `coderun --check-update` | Check for a newer release. |
| `coderun --update` | Update the installed runner. |
| `coderun --uninstall` | Remove the installed runner and its PATH entry. |
| `coderun -h`, `coderun --help` | Show help. |
| `coderun -v`, `coderun --version` | Show the installed version. |

Notes:

- `--compile` and `--clean` cannot be combined.
- `--compile` works for compiled languages. Interpreted languages return an unsupported-operation error.
- `-o` / `--output` works for C, C++, Rust, Go, Swift, and Kotlin. It is not supported for Java or interpreted languages.
- The output path must not be the source file itself.
- On Linux and macOS, use `coderun -- <file>` if the filename begins with `-`.

### Help and version

```bash
coderun --help
coderun --version
```

`--help` prints usage, grouped options, supported languages, and examples. `--version` prints `coderun <version>`.

### Language and environment information

```bash
coderun --list
coderun --check
coderun --info
```

- `--list` prints all 19 languages with their extensions and whether they are compiled or interpreted.
- `--check` verifies each required compiler/runtime and exits `1` if any are missing.
- `--info` prints the version, install path, operating system, architecture, and shell (PowerShell version on Windows).

### Compile, clean, and custom output

```bash
coderun --compile main.cpp
coderun --clean main.cpp
coderun -o app main.cpp
coderun --output build/app main.cpp
```

`--compile` writes the artifact and reports the artifact location without running it. `--clean` removes artifacts. `-o` chooses a custom artifact name and runs the result in normal execution mode.

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
| Python, R, JavaScript, TypeScript, PHP, Ruby, Bash, Lua, Perl, Julia, Dart, Elixir | none | none | No build step |

For example, `main.cpp` becomes `main` on Linux/macOS and `main.exe` on Windows.

### Custom output with `-o` / `--output`

```bash
coderun -o app main.cpp
coderun --output build/app main.cpp
```

Rules:

- Supported for C, C++, Rust, Go, Swift, and Kotlin.
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
- removes Java class files matching the source name, including inner classes, in the source directory;
- reports when an interpreted language has nothing to clean;
- exits `0` when the clean completes, even if there was nothing to remove;
- exits `1` for validation or removal failures.

---

## How it works

```text
coderun main.cpp
      │
      ├─ 1. Read the file extension (.cpp)
      ├─ 2. Validate the mode and options
      ├─ 3. Select the platform compiler (g++ / clang++ / g++)
      ├─ 4. Compile to an artifact
      ├─ 5. Run the artifact
      └─ 6. Exit with the program's exit code
```

For interpreted files, steps 4 and 5 become a single interpreter call:

```text
coderun app.py
      └─ python3 app.py → exit with the program's exit code
```

### Compiler selection

| Platform | C | C++ |
| --- | --- | --- |
| Linux | `gcc` | `g++` |
| macOS | `clang` | `clang++` |
| Windows | `gcc` | `g++` |

The other runtimes use the same tool names on every platform, except Python: `python3` on Linux/macOS and `python` on Windows.

---

## Requirements and toolchains

### coderun itself

| Platform | Requirements |
| --- | --- |
| Linux | Bash; `curl` or `wget` for `--update` and `--check-update` |
| macOS | Bash; `curl` or `wget` for `--update` and `--check-update` |
| Windows | PowerShell (`--update` and `--check-update` use the built-in `Invoke-WebRequest`) |

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
| `node` | JavaScript | https://nodejs.org/ |
| `tsx` | TypeScript | `npm install -g tsx` |
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

</details>

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
# coderun 2.3.1
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
- If a newer version is available, it downloads the platform-specific runner, replaces the installed copy, and reports the new version.

`--update` requires V2.1.0 or newer; older versions must upgrade once using the installer or a manual download. See [Upgrading from V1.0.0 or V2.0.0](#upgrading-from-v100-or-v200).

- Linux/macOS: requires `curl` or `wget`.
- Windows: uses PowerShell's `Invoke-WebRequest`.
- The runner must already be installed in the standard location.
- Downloads are validated before replacing the existing runner.
- A failed version check or download leaves the installed runner unchanged.

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

- `coderun --check`: `1` if any required dependency is missing.
- `coderun --check-update`: `1` if a newer release exists or the check fails.
- `coderun --compile`: the compiler's exit code on failure, `0` on success.
- `coderun <file>`: the compiler's exit code if compilation fails, otherwise the program's exit code.

---

## Project structure

```text
coderun/
├── bin/
│   ├── coderun          # Linux runner
│   └── coderun-mac      # macOS runner
├── windows/
│   └── coderun.ps1      # Windows runner
├── install.sh           # Linux installer
├── install-mac.sh       # macOS installer
├── install.ps1          # Windows installer
├── install.cmd          # Command Prompt wrapper for install.ps1
├── coderun              # Legacy root copy of the Linux runner
├── VERSION              # Release version (2.3.1)
├── README.md
└── LICENSE
```

| Path | Purpose |
| --- | --- |
| `bin/coderun` | Bash runner for Linux |
| `bin/coderun-mac` | Bash runner for macOS |
| `windows/coderun.ps1` | PowerShell runner for Windows |
| `install.sh` | Installs the Linux runner to `~/.local/bin` |
| `install-mac.sh` | Installs the macOS runner to `~/.local/bin` |
| `install.ps1` | Installs the Windows runner to `%USERPROFILE%\bin` |
| `install.cmd` | Command Prompt wrapper for `install.ps1` |
| `coderun` | Legacy copy of the Linux runner |
| `VERSION` | Single tracked release version, mirrored in the runners |
| `README.md` | Project documentation |
| `LICENSE` | MIT license |

---

## Troubleshooting

| Problem | Fix |
| --- | --- |
| `coderun: command not found` | Open a new terminal. Confirm `~/.local/bin` (Linux/macOS) or `%USERPROFILE%\bin` (Windows) is on PATH. |
| Installer reports `gcc`/`g++` missing | Install a C/C++ toolchain. On Ubuntu/Debian: `sudo apt install build-essential`. On Windows: MinGW-w64 or MSYS2. |
| Installer reports `clang` missing on macOS | Run `xcode-select --install`. |
| `--check` reports missing tools | Install the toolchain for the language you need, or ignore languages you do not use. |
| `tsx` not found | Install Node.js, then run `npm install -g tsx`. |
| A `.java` file does not run | Use Java 11 or newer for source-file execution. Check with `java -version`. |
| Kotlin does not run | Ensure both `kotlinc` and `java` are on PATH. |
| `bash` not found on Windows | Install Git Bash, WSL, or MSYS2 and add `bash` to PATH. |
| PowerShell blocks `install.ps1` | Run `powershell -ExecutionPolicy Bypass -File .\install.ps1`. |
| `--check-update` exits `1` | `1` means a newer release is available or the check failed. Read the message. |
| `--update` fails | Check your network connection and, on Linux/macOS, that `curl` or `wget` is installed. |
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

### Current release: V2.3.1

V2.3.1 makes `--update` version-aware and adds a Command Prompt installer:

- Running `coderun --update` now checks the published `VERSION` before downloading.
- When the installed version is current, it prints `coderun is up to date (2.3.1).` and exits `0` without replacing the runner.
- When a newer release exists, it downloads it and prints `coderun updated successfully to <version>.`
- A failed version check or download exits `1` and leaves the installed runner untouched.
- Added `install.cmd`, which runs `install.ps1` from Command Prompt with the execution policy bypassed.
- `--check-update` and all language behavior are unchanged.

V2.3.0 added Lua, Perl, Julia, Dart, and Elixir; see the release history below.

### Release history

| Version | Release | Highlights |
| --- | --- | --- |
| V1.0.0 | [v1.0.0](https://github.com/pjprogrammers/coderun/releases/tag/v1.0.0) | Initial release with C, C++, and Python support |
| V2.0.0 | [v2.0.0](https://github.com/pjprogrammers/coderun/releases/tag/v2.0.0) | Expanded to 14 languages |
| V2.1.0 | [v2.1.0](https://github.com/pjprogrammers/coderun/releases/tag/v2.1.0) | Added help, version, update, and uninstall flags |
| V2.2.0 | [v2.2.0](https://github.com/pjprogrammers/coderun/releases/tag/v2.2.0) | Added list, check, info, check-update, compile, clean, and output options |
| V2.3.0 | [v2.3.0](https://github.com/pjprogrammers/coderun/releases/tag/v2.3.0) | Added Lua, Perl, Julia, Dart, and Elixir |
| V2.3.1 | [v2.3.1](https://github.com/pjprogrammers/coderun/releases/tag/v2.3.1) | Made `--update` version-aware and added a Command Prompt installer |

---

## Contributing

1. Fork the repository.
2. Create a branch for your change.
3. Update the relevant runner:
   - Linux: `bin/coderun`
   - macOS: `bin/coderun-mac`
   - Windows: `windows/coderun.ps1`
4. If you change the Linux runner, keep the legacy root `coderun` copy in sync.
5. Keep the version constant in each runner in sync with `VERSION`.
6. Test the behavior you changed, including exit codes and paths with spaces.
7. Open a pull request describing the change and the platform you tested.

There is no build step: the shell and PowerShell scripts are the product.

---

## License

MIT. See [LICENSE](LICENSE).
