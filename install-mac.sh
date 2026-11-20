#!/usr/bin/env bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE="$SCRIPT_DIR/bin/coderun-mac"
INSTALL_DIR="$HOME/.local/bin"
WARNED=0

if [ ! -f "$SOURCE" ]; then
    echo "Error: runner not found at $SOURCE."
    exit 1
fi

if [ -f "$INSTALL_DIR/coderun" ]; then
    echo "Existing installation found - upgrading..."
else
    echo "Installing coderun for macOS..."
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

warn_missing clang "Install Apple's Command Line Tools with: xcode-select --install"
warn_missing clang++ "Install Apple's Command Line Tools with: xcode-select --install"
warn_missing python3 "Install Python from https://www.python.org/downloads/."

if [ "$WARNED" -eq 1 ]; then
    echo
    echo "Run 'coderun --check' after installation to see which toolchains are ready."
fi

mkdir -p "$INSTALL_DIR"

cp "$SOURCE" "$INSTALL_DIR/coderun"
chmod 755 "$INSTALL_DIR/coderun"

SHELL_CONFIG=""

if [ -f "$HOME/.zshrc" ]; then
    SHELL_CONFIG="$HOME/.zshrc"
else
    SHELL_CONFIG="$HOME/.zprofile"
    touch "$SHELL_CONFIG"
fi

if ! grep -qF 'export PATH="$HOME/.local/bin:$PATH"' "$SHELL_CONFIG" 2>/dev/null; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$SHELL_CONFIG"
fi

export PATH="$HOME/.local/bin:$PATH"

if [ -n "${ZSH_VERSION:-}" ]; then
    # shellcheck disable=SC1090
    source "$SHELL_CONFIG"
fi

echo
echo "coderun installed successfully!"
echo "Location: $INSTALL_DIR/coderun"

echo
echo "Try:"
echo "  coderun main.cpp"
echo "  coderun main.py --verbose"
echo "  coderun --check"
echo
