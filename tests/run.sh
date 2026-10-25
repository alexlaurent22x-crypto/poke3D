#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
export XDG_DATA_HOME="${XDG_DATA_HOME:-/tmp/poke3d-xdg/data}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-/tmp/poke3d-xdg/config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-/tmp/poke3d-xdg/cache}"
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
godot --headless --path . --editor --import --quit
godot --headless --path . --script res://tests/test_poker.gd
godot --headless --path . --script res://tests/test_visual_assets.gd
godot --headless --path . --script res://tests/test_scene.gd
