#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cp -p "$ROOT/bin/coderun" "$ROOT/bin/coderun-mac"
cp -p "$ROOT/bin/coderun" "$ROOT/coderun"
chmod 755 "$ROOT/bin/coderun" "$ROOT/bin/coderun-mac" "$ROOT/coderun"

echo "Synced bin/coderun-mac and coderun from bin/coderun."
