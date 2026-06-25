#!/usr/bin/env bash
set -euo pipefail

# One-shot: build signed Android APK (copied to ~/Desktop/GymLog.apk), build
# release iOS, and install on the connected iPhone if one is paired.
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
IOS_APP="$HOME/Library/Caches/treinolog_build/ios/iphoneos/Runner.app"

cd "$PROJECT_ROOT"

echo "▶ Android APK"
"$SCRIPT_DIR/build_apk.sh"

echo ""
echo "▶ iOS release"
"$SCRIPT_DIR/build_ios.sh" --release

echo ""
echo "▶ Procurando iPhone conectado…"
# Match the first paired UUID (8-4-4-4-12 hex chars) on an iPhone line.
DEVICE_ID=$(xcrun devicectl list devices 2>/dev/null \
  | grep -E 'iPhone.*available' \
  | grep -oE '[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}' \
  | head -1)

if [[ -n "${DEVICE_ID:-}" ]]; then
  echo "→ Instalando em $DEVICE_ID"
  xcrun devicectl device install app --device "$DEVICE_ID" "$IOS_APP"
  echo "→ Abrindo app"
  xcrun devicectl device process launch --device "$DEVICE_ID" com.lucasbarrense.gymlog || true
else
  echo "⚠ Nenhum iPhone pareado. Conecte por cabo e rode novamente para instalar."
fi

echo ""
echo "✓ Pronto."
echo "  Android APK: $HOME/Desktop/GymLog.apk"
echo "  iOS Runner.app: $IOS_APP"
