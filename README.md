# coderun

A tiny cross-platform command-line runner for **14 programming languages**.

`coderun` compiles and runs compiled languages and directly runs interpreted languages using a single command.

```bash
coderun main.cpp
coderun main.c
coderun main.py
```

**Version:** V2.2.0

**Previous Version:** V2.1.0

---

## Features

- Simple `coderun <file>` command
- Help flags: `coderun -h` and `coderun --help`
- Version check with `coderun -v` and `coderun --version`
- Language listing with `coderun --list`
- Dependency checks with `coderun --check`
- Installation details with `coderun --info`
- Update checks with `coderun --check-update`
- Compile-only and clean modes with `coderun --compile` and `coderun --clean`
- Custom artifact names with `coderun -o` and `coderun --output`
- Self-update with `coderun --update`
- Clean removal with `coderun --uninstall`
- Supports C, C++, Python, R, Java, Rust, JavaScript, TypeScript, Go, PHP, Ruby, Bash, Swift and Kotlin
- Automatic compilation for compiled languages
- Uses GCC/G++ on Linux
- Uses Clang/Clang++ on macOS
- Uses GCC/G++ on Windows
- Automatically adds `coderun` to your PATH
- No manual PATH configuration required
- Compiled executables are created beside the source file
- Direct execution for interpreted languages
- Automatic execution after successful compilation

---

## Project Structure

```text
coderun/
│
├── bin/
│   ├── coderun
│   └── coderun-mac
│
├── windows/
│   └── coderun.ps1
│
├── install.sh
├── install-mac.sh
├── install.ps1
│
├── VERSION
├── README.md
└── LICENSE
```

### File Overview

| File | Purpose |
| --------------------- | ---------------------------------- |
| `bin/coderun` | Runner used on Linux-based systems |
| `bin/coderun-mac` | Runner used on macOS |
| `windows/coderun.ps1` | Runner used on Windows |
| `install.sh` | Automated Linux installation |
| `install-mac.sh` | Automated macOS installation |
| `install.ps1` | Automated Windows installation |
| `VERSION` | Current project version |
| `README.md` | Project documentation |
| `LICENSE` | Project license |

---

## Supported Platforms

| Language | Extension | Linux | macOS | Windows |
| -------- | --------- | ----- | ----- | ------- |
| C | `.c` | GCC | Clang | GCC |
| C++ | `.cpp` | G++ | Clang++ | G++ |
| Python | `.py` | Python 3 | Python 3 | Python |
| R | `.R`, `.r` | Rscript | Rscript | Rscript |
| Java | `.java` | Java 11+ | Java 11+ | Java 11+ |
| Rust | `.rs` | rustc | rustc | rustc |
| JavaScript | `.js` | Node.js | Node.js | Node.js |
| TypeScript | `.ts` | tsx | tsx | tsx |
| Go | `.go` | Go | Go | Go |
| PHP | `.php` | PHP | PHP | PHP |
| Ruby | `.rb` | Ruby | Ruby | Ruby |
| Bash | `.sh` | Bash | Bash | Bash |
| Swift | `.swift` | Swift | Swift | Swift |
| Kotlin | `.kt` | Kotlin compiler | Kotlin compiler | Kotlin compiler |

The required compiler or interpreter must already be installed on the system and accessible through PATH. Linux, macOS and Windows all support the same set of languages.

---

## Installation

Clone the repository:

```bash
git clone https://github.com/pjprogrammers/coderun.git
cd coderun
```

### Linux

Run:

```bash
./install.sh
```

The installer:

- Checks for GCC, G++, and Python 3
- Installs `coderun` to `~/.local/bin`
- Adds `~/.local/bin` to your Bash PATH if required
- Makes the command executable
- Configures the environment automatically

**Important:** The PATH change does not affect the terminal currently running the installer. After the installation finishes, **close the current terminal and open a new terminal** before using `coderun`.

Then run:

```bash
coderun main.cpp
```

### macOS

Run:

```bash
./install-mac.sh
```

The installer:

- Checks for Clang, Clang++, and Python 3
- Installs `coderun` to `~/.local/bin`
- Adds the directory to your shell PATH if required
- Makes the command executable
- Configures the environment automatically

**Important:** The PATH change does not affect the terminal currently running the installer. After the installation finishes, **close the current terminal and open a new terminal** before using `coderun`.

Then run:

```bash
coderun main.cpp
```

### Windows

Open PowerShell in the project directory and run:

```powershell
.\install.ps1
```

The installer:

- Checks for GCC, G++, and Python
- Installs `coderun` to `%USERPROFILE%\bin`
- Creates the Windows command launcher automatically
- Adds the installation directory to the User PATH
- Requires no manual Environment Variable configuration

**Important:** The PATH change does not affect the terminal currently running the installer. After the installation finishes, **close the current PowerShell or Command Prompt window and open a new terminal** before using `coderun`.

Then run:

```powershell
coderun main.cpp
```

---

## Usage

### Help

```bash
coderun -h
coderun --help
```

Displays the available options, supported languages and examples.

### Version

```bash
coderun -v
coderun --version
```

Displays the installed version.

### List Supported Languages

```bash
coderun --list
```

Lists all 14 supported languages with their extensions and whether they are compiled or interpreted.

### Check Dependencies

```bash
coderun --check
```

Checks whether the required compilers and runtimes are installed and on PATH. It exits with `0` when every dependency is available and `1` when one or more are missing.

### System Information

```bash
coderun --info
```

Displays the installed version, runner path, operating system, architecture and shell.

### Check for Updates

```bash
coderun --check-update
```

Downloads the published `VERSION` file and compares it with the installed version without changing anything. It exits with `1` when a newer version is available and `0` when the installed version is current or newer.

### Compile Without Running

```bash
coderun --compile main.cpp
```

Compiles a source file and reports the generated artifact without executing it. This is available for C, C++, Java, Rust, Go, Swift and Kotlin. Interpreted languages return a clear unsupported-operation error.

### Custom Output

```bash
coderun -o app main.cpp
coderun --output build/program main.cpp
```

Sets the output artifact for compiled languages. On Windows, `.exe` is appended when the output name has no extension. Kotlin appends `.jar` when no extension is supplied. `-o` is available for C, C++, Rust, Go, Swift and Kotlin; it is not supported for Java.

### Clean Build Artifacts

```bash
coderun --clean main.cpp
coderun --clean -o app main.cpp
```

Removes the generated executable, jar or Java class files for the given source file. Interpreted languages report that they have no build artifacts.

### Update

```bash
coderun --update
```

Downloads the latest version from the project repository and replaces the installed runner. On Linux and macOS, `curl` or `wget` is required.

### Uninstall

```bash
coderun --uninstall
```

Removes the installed runner and its PATH entry.

### C++

```bash
coderun main.cpp
```

The program is compiled and executed automatically.

For example:

```text
main.cpp
```

becomes:

```text
main.cpp
main
```

on Linux/macOS, or:

```text
main.cpp
main.exe
```

on Windows.

### C

```bash
coderun main.c
```

### Python

```bash
coderun main.py
```

Python files are executed directly without compilation.

### R

```bash
coderun analysis.R
```

R files are executed using `Rscript`.

### Java

```bash
coderun Main.java
```

Java source-file execution requires Java 11 or newer.

### Rust

```bash
coderun main.rs
```

Rust files are compiled and executed automatically.

### JavaScript

```bash
coderun app.js
```

JavaScript files are executed using Node.js.

### TypeScript

```bash
coderun app.ts
```

TypeScript files are executed using `tsx`.

### Go

```bash
coderun main.go
```

Go files are executed using `go run`.

### PHP

```bash
coderun index.php
```

### Ruby

```bash
coderun script.rb
```

### Bash

```bash
coderun script.sh
```

### Swift

```bash
coderun main.swift
```

### Kotlin

```bash
coderun Main.kt
```

Kotlin files are compiled into an executable JAR and run using Java.

---

## How It Works

`coderun` determines the file type from its extension.

```text
.cpp  → C++ compiler → Execute
.c    → C compiler   → Execute
.py   → Python       → Execute
.R    → Rscript      → Execute
.java → Java         → Execute
.rs   → Rust compiler → Execute
.js   → Node.js      → Execute
.ts   → tsx          → Execute
.go   → Go           → Execute
.php  → PHP          → Execute
.rb   → Ruby         → Execute
.sh   → Bash         → Execute
.swift → Swift       → Execute
.kt   → Kotlin compiler → Execute
```

The compiler or runtime used depends on the operating system and installed development tools.

```text
Linux
.cpp → g++
.c   → gcc

macOS
.cpp → clang++
.c   → clang

Windows
.cpp → g++
.c   → gcc
```

---

## Requirements

### Linux

Required for the original language support:

```text
gcc
g++
python3
```

On Ubuntu/Debian-based distributions, you can install the C/C++ toolchain with:

```bash
sudo apt install build-essential
```

Additional languages require their respective compilers or runtimes:

```text
Rscript
Java 11+
rustc
Node.js
tsx
Go
PHP
Ruby
Bash
Swift
Kotlin compiler
```

### macOS

Required for the original language support:

```text
clang
clang++
python3
```

Apple's Command Line Tools provide Clang and Clang++:

```bash
xcode-select --install
```

Additional languages require their respective compilers or runtimes.

### Windows

Required for the original language support:

```text
gcc
g++
python
```

A GCC distribution such as MinGW-w64 or MSYS2 can be used for C/C++ development.

Additional languages require their respective compilers or runtimes to be installed and accessible through PATH.

---

## Example

Suppose you have:

```text
project/
└── main.cpp
```

Run:

```bash
coderun main.cpp
```

`coderun` compiles the program and immediately runs it.

After compilation:

```text
project/
├── main.cpp
└── main
```

On Windows:

```text
project/
├── main.cpp
└── main.exe
```

---

## Error Handling

If no file is provided:

```bash
coderun
```

you will see:

```text
Usage: coderun <file>
```

If the file does not exist:

```text
Error: file not found: main.cpp
```

If an unsupported extension is used:

```text
Unsupported file type: .unknown
Supported: .py .cpp .c .R .r .java .rs .js .ts .go .php .rb .sh .swift .kt
```

---

## Why coderun?

Running small programs normally requires remembering different commands.

For C++:

```bash
g++ main.cpp -o main
./main
```

For C:

```bash
gcc main.c -o main
./main
```

For Python:

```bash
python3 main.py
```

With `coderun`:

```bash
coderun main.cpp
coderun main.c
coderun main.py
coderun analysis.R
coderun Main.java
coderun main.rs
```

One command handles the rest.

---

## Version

The current version is recorded in the [`VERSION`](VERSION) file and is available at runtime with `coderun --version`.

### V2.2.0 — Information and Build Commands

**Release type:** Minor feature release

**Highlights:**

- Added `--list` to display all supported languages and file types.
- Added `--check` to verify required compilers and runtimes, with a nonzero exit code when dependencies are missing.
- Added `--info` to display the version, install path, operating system, architecture and shell.
- Added `--check-update` to compare the installed version with the published version.
- Added `--compile` to compile without executing; interpreted languages report an unsupported operation.
- Added `--clean` to remove generated executables, jars and Java class files.
- Added `-o` and `--output` for custom compiled artifact names.
- Preserved compiler and program exit codes across all platforms.

### V2.1.0 — Command-Line Options

**Release type:** Minor feature release

**Highlights:**

- Added `-h` and `--help` to display usage, options and supported languages.
- Added `-v` and `--version` to display the installed version.
- Added `--update` to download and install the latest runner.
- Added `--uninstall` to remove the installed runner and its PATH entry.
- Updated the Linux, macOS and Windows runners together.

### V2.0.0 — Multi-Language Support

**Release type:** Major feature release

**Highlights:**

- Expanded language support from 3 languages to 14.
- Added R, Java, Rust, JavaScript, TypeScript, Go, PHP, Ruby, Bash, Swift and Kotlin.
- Added automatic compilation and execution for supported compiled languages.
- Added direct execution for supported interpreted languages.
- Retained the original cross-platform project structure and installation workflow.

### Versioning Policy

`coderun` follows [Semantic Versioning](https://semver.org/).

Versions use the `MAJOR.MINOR.PATCH` format:

| Component | Meaning |
| --------- | ------- |
| MAJOR | Incompatible changes to the command or its behavior |
| MINOR | New features that remain backward-compatible |
| PATCH | Backward-compatible bug fixes |

### Release History

| Version | Description |
| ------- | ----------- |
| V1.0.0 | Initial release with C, C++ and Python support |
| V2.0.0 | Expanded language support and multi-language execution |
| V2.1.0 | Added help, version, update and uninstall flags |
| V2.2.0 | Added language, dependency, system, update-check, compile, clean and output options |

### Current Supported File Types

```text
.c
.cpp
.py
.R
.r
.java
.rs
.js
.ts
.go
.php
.rb
.sh
.swift
.kt
```

**Note:** All platform runners implement the same language support. A language runs only when its compiler or runtime is installed.

---

## License

See the [LICENSE](https://github.com/pjprogrammers/coderun/blob/main/LICENSE) file for license information.
