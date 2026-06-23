#!/usr/bin/env bash
# Build the Hub OS image via CustomPiOS (Docker).
#   git submodule update --init --recursive   # first time: pulls src/CustomPiOS
#   sudo bash ./build.sh
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
CPOS="$DIR/src/CustomPiOS"
if [ ! -d "$CPOS/src" ]; then
  echo "CustomPiOS submodule missing. Run: git submodule add https://github.com/guysoft/CustomPiOS.git src/CustomPiOS" >&2
  exit 1
fi
# CustomPiOS Docker build: reads src/config + src/modules/*, emits workspace/*.img
cd "$DIR/src"
"$CPOS/src/build_dist"
