#!/usr/bin/env bash
set -euo pipefail

# Build signed release APK and copy to ~/Desktop/GymLog.apk for sharing.
# Auto-bumps the build number in pubspec.yaml so each APK is a fresh version
# (Android refuses to install an APK with the same versionCode over itself).
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="$HOME/Desktop/my-apps/GymLog.apk"

cd "$PROJECT_ROOT"

# Bump pubspec version: 1.0.0+5 → 1.0.0+6
CURRENT_LINE=$(grep -E '^version: ' pubspec.yaml)
CURRENT_VERSION=$(echo "$CURRENT_LINE" | awk '{print $2}')
NAME_PART="${CURRENT_VERSION%+*}"
BUILD_PART="${CURRENT_VERSION#*+}"
if [[ "$BUILD_PART" == "$CURRENT_VERSION" ]]; then
  # No build number → start at 1
  BUILD_PART=0
fi
NEW_BUILD=$((BUILD_PART + 1))
NEW_VERSION="${NAME_PART}+${NEW_BUILD}"

# macOS sed requires the empty arg after -i
sed -i '' "s/^version: .*/version: ${NEW_VERSION}/" pubspec.yaml
echo "→ Versão: ${CURRENT_VERSION} → ${NEW_VERSION}"

flutter build apk --release

cp build/app/outputs/flutter-apk/app-release.apk "$DEST"

SIZE=$(du -h "$DEST" | cut -f1)
echo ""
echo "✓ APK pronto: $DEST ($SIZE)"
echo "  Versão ${NEW_VERSION} — compartilhe pelo WhatsApp como documento."
