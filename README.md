# coderun

A tiny cross-platform command-line runner for **C, C++ and Python**.

`coderun` lets you compile and run C/C++ programs or directly run Python files using a single command.

```bash
coderun main.cpp
coderun main.c
coderun main.py
```

**Version:** V1

---

## Features

* Simple `coderun <file>` command
* Supports C, C++ and Python
* Automatic compilation for C and C++
* Uses GCC/G++ on Linux
* Uses Clang/Clang++ on macOS
* Uses GCC/G++ on Windows
* Automatically adds `coderun` to your PATH
* No manual PATH configuration required
* Compiled executables are created beside the source file

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

| File                  | Purpose                            |
| --------------------- | ---------------------------------- |
| `bin/coderun`         | Runner used on Linux-based systems |
| `bin/coderun-mac`     | Runner used on macOS               |
| `windows/coderun.ps1` | Runner used on Windows             |
| `install.sh`          | Automated Linux installation       |
| `install-mac.sh`      | Automated macOS installation       |
| `install.ps1`         | Automated Windows installation     |
| `README.md`           | Project documentation              |
| `LICENSE`             | Project license                    |

---

## Supported Platforms

| Platform | C     | C++     | Python   |
| -------- | ----- | ------- | -------- |
| Linux    | GCC   | G++     | Python 3 |
| macOS    | Clang | Clang++ | Python 3 |
| Windows  | GCC   | G++     | Python   |

The required compiler or interpreter must already be installed on the system.

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

* Checks for GCC, G++, and Python 3
* Installs `coderun` to `~/.local/bin`
* Adds `~/.local/bin` to your Bash PATH if required
* Makes the command executable
* Configures the environment automatically

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

* Checks for Clang, Clang++, and Python 3
* Installs `coderun` to `~/.local/bin`
* Adds the directory to your shell PATH if required
* Makes the command executable
* Configures the environment automatically

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

* Checks for GCC, G++, and Python
* Installs `coderun` to `%USERPROFILE%\bin`
* Creates the Windows command launcher automatically
* Adds the installation directory to the User PATH
* Requires no manual Environment Variable configuration

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

---

## How It Works

`coderun` determines the file type from its extension.

```text
.cpp  → C++ compiler → Execute
.c    → C compiler   → Execute
.py   → Python       → Execute
```

The compiler used depends on the operating system.

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

Required:

```text
gcc
g++
python3
```

On Ubuntu/Debian-based distributions, you can install the C/C++ toolchain with:

```bash
sudo apt install build-essential
```

### macOS

Required:

```text
clang
clang++
python3
```

Apple's Command Line Tools provide Clang and Clang++:

```bash
xcode-select --install
```

### Windows

Required:

```text
gcc
g++
python
```

A GCC distribution such as MinGW-w64 or MSYS2 can be used for C/C++ development.

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
Unsupported file type: .java
Supported: .py .cpp .c
```

---

## Why coderun?

Running small C, C++ and Python programs normally requires remembering different commands:

```bash
g++ main.cpp -o main
./main
```

or:

```bash
gcc main.c -o main
./main
```

or:

```bash
python3 main.py
```

With `coderun`:

```bash
coderun main.cpp
coderun main.c
coderun main.py
```

One command handles the rest.

---

## Version

**V1**

Current supported file types:

```text
.c
.cpp
.py
```

---

## License

See the [LICENSE](https://github.com/pjprogrammers/coderun/blob/main/LICENSE) file for license information.

