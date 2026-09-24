#!/usr/bin/env bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE="$SCRIPT_DIR/bin/coderun-mac"
INSTALL_DIR="$HOME/.local/bin"

echo "Installing coderun for macOS..."

if ! command -v clang >/dev/null 2>&1; then
    echo "Error: clang is not installed."
    echo "Install Apple's Command Line Tools with:"
    echo "  xcode-select --install"
    exit 1
fi

if ! command -v clang++ >/dev/null 2>&1; then
    echo "Error: clang++ is not installed."
    echo "Install Apple's Command Line Tools with:"
    echo "  xcode-select --install"
    exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
    echo "Error: python3 is not installed."
    exit 1
fi

mkdir -p "$INSTALL_DIR"

cp "$SOURCE" "$INSTALL_DIR/coderun"
chmod +x "$INSTALL_DIR/coderun"

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
    source "$SHELL_CONFIG"
fi

echo
echo "coderun installed successfully!"
echo "Location: $INSTALL_DIR/coderun"

echo
echo "Try:"
echo "  coderun main.cpp"
