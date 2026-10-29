# coderun

A tiny cross-platform command-line runner for **C, C++ and Python**.

`coderun` lets you compile and run C/C++ programs or directly run Python files using a single command.

```bash
coderun main.cpp
coderun main.c
coderun main.py
```

**Version:** V2.0.0

**Previous Version:** V1.0.0

---

## Features

- Simple `coderun <file>` command
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

The required compiler or interpreter must already be installed on the system.

Windows support for the additional languages depends on the corresponding runtime or compiler being installed and accessible through PATH. The Windows runner must also implement the corresponding language options.

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

Additional languages require their respective compilers or runtimes, and the Windows runner must support their execution.

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

**Note:** The documented language support must match the implementations in each platform's runner. The Windows runner and installation scripts may need updates before V2 can be considered fully cross-platform.

---

## License

See the [LICENSE](https://github.com/pjprogrammers/coderun/blob/main/LICENSE) file for license information.
