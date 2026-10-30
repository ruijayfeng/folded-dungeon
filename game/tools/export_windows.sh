#!/usr/bin/env bash
# Exports the Windows Desktop preset. Requires Godot export templates for 4.7.2.
set -euo pipefail
GAME_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT_BIN="${GODOT_BIN:-$GAME_DIR/../.tools/Godot.app/Contents/MacOS/Godot}"
mkdir -p "$GAME_DIR/build/windows"
"$GODOT_BIN" --headless --path "$GAME_DIR" --export-release "Windows Desktop" "$GAME_DIR/build/windows/FoldedDungeon.exe" "$@"
echo "exported: $GAME_DIR/build/windows/FoldedDungeon.exe"
