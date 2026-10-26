#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
python3 Tools/download_assets.py
python3 Tools/normalize_gltf.py
blender --background --python-exit-code 1 --python Tools/build_unity_art.py
blender --background --python-exit-code 1 --python Tools/build_standing_cast.py
blender --background --python-exit-code 1 --python Tools/validate_art.py
python3 Tools/generate_original_media.py
