#!/usr/bin/env bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE="$SCRIPT_DIR/bin/coderun"
INSTALL_DIR="$HOME/.local/bin"
BASHRC="$HOME/.bashrc"
WARNED=0

if [ ! -f "$SOURCE" ]; then
    echo "Error: runner not found at $SOURCE."
    exit 1
fi

if [ -f "$INSTALL_DIR/coderun" ]; then
    echo "Existing installation found - upgrading..."
else
    echo "Installing coderun for Linux..."
fi

warn_missing() {
    local tool="$1"
    local hint="$2"

    if ! command -v "$tool" >/dev/null 2>&1; then
        if [ "$WARNED" -eq 0 ]; then
            echo
            echo "Note: coderun does not require these tools to install,"
            echo "but languages that use them will not run until they are available."
            WARNED=1
        fi
        echo "  warning: $tool was not found. $hint"
    fi
}

warn_missing gcc "Install a C toolchain (for example: sudo apt install build-essential)."
warn_missing g++ "Install a C++ toolchain (for example: sudo apt install build-essential)."
warn_missing python3 "Install Python from https://www.python.org/downloads/."

if [ "$WARNED" -eq 1 ]; then
    echo
    echo "Run 'coderun --check' after installation to see which toolchains are ready."
fi

mkdir -p "$INSTALL_DIR"

cp "$SOURCE" "$INSTALL_DIR/coderun"
chmod 755 "$INSTALL_DIR/coderun"

if ! grep -qF 'export PATH="$HOME/.local/bin:$PATH"' "$BASHRC" 2>/dev/null; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$BASHRC"
fi

export PATH="$HOME/.local/bin:$PATH"

echo
echo "coderun installed successfully!"
echo "Location: $INSTALL_DIR/coderun"

if [ -n "${BASH_VERSION:-}" ] && [ -f "$BASHRC" ]; then
    # shellcheck disable=SC1090
    source "$BASHRC"
fi

echo
echo "Try:"
echo "  coderun main.cpp"
echo "  coderun main.py --verbose"
echo "  coderun --check"
echo
