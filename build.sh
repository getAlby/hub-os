#!/usr/bin/env bash
# Build the Hub OS image. First time: git submodule update --init --recursive
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
[ -d "$DIR/src/CustomPiOS/src" ] || { echo "Run: git submodule update --init --recursive" >&2; exit 1; }
exec sudo bash "$DIR/src/build_dist" "$@"
