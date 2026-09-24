#!/usr/bin/env bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE="$SCRIPT_DIR/bin/coderun"
INSTALL_DIR="$HOME/.local/bin"
BASHRC="$HOME/.bashrc"

echo "Installing coderun for Linux..."

if ! command -v gcc >/dev/null 2>&1; then
    echo "Error: gcc is not installed."
    echo "Install it with:"
    echo "  sudo apt install build-essential"
    exit 1
fi

if ! command -v g++ >/dev/null 2>&1; then
    echo "Error: g++ is not installed."
    echo "Install it with:"
    echo "  sudo apt install build-essential"
    exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
    echo "Error: python3 is not installed."
    exit 1
fi

mkdir -p "$INSTALL_DIR"

cp "$SOURCE" "$INSTALL_DIR/coderun"
chmod +x "$INSTALL_DIR/coderun"

if ! grep -qF 'export PATH="$HOME/.local/bin:$PATH"' "$BASHRC" 2>/dev/null; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$BASHRC"
fi

export PATH="$HOME/.local/bin:$PATH"

echo
echo "coderun installed successfully!"
echo "Location: $INSTALL_DIR/coderun"

if [ -n "${BASH_VERSION:-}" ]; then
    source "$BASHRC"
fi

echo
echo "Try:"
echo "  coderun main.cpp"
