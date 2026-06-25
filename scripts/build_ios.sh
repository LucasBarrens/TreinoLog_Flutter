#!/usr/bin/env bash
set -euo pipefail

# Build iOS outside iCloud Drive to avoid CodeSign failures from File Provider
# adding com.apple.FinderInfo xattrs to Runner.app between Thin Binary and CodeSign.
#
# Usage:
#   ./scripts/build_ios.sh                  # debug build
#   ./scripts/build_ios.sh --release        # release build
#   ./scripts/build_ios.sh --no-codesign    # passthrough flags

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
EXTERNAL_BUILD="$HOME/Library/Caches/treinolog_build"

mkdir -p "$EXTERNAL_BUILD/ios"
mkdir -p "$PROJECT_ROOT/build"

cd "$PROJECT_ROOT"

# Replace build/ios with a symlink to a non-iCloud location.
if [ -L "build/ios" ]; then
  :
elif [ -e "build/ios" ]; then
  rm -rf "build/ios"
fi
# Clean any iCloud-renamed leftovers.
find "$PROJECT_ROOT/build" -maxdepth 1 -name "ios *" -exec rm -rf {} \; 2>/dev/null || true
ln -sfn "$EXTERNAL_BUILD/ios" "build/ios"

flutter build ios "$@"

echo ""
echo "Runner.app: $EXTERNAL_BUILD/ios/iphoneos/Runner.app"
