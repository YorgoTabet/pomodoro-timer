#!/bin/bash
#
# Builds Pomodoro.app and installs it.
#
#   ./Scripts/build.sh            build + install to /Applications
#   ./Scripts/build.sh --no-install   build the bundle into .build/ only
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

APP_NAME="Pomodoro"
BUNDLE=".build/${APP_NAME}.app"
INSTALL=1
[[ "${1:-}" == "--no-install" ]] && INSTALL=0

echo "==> Building release binary"
swift build -c release --product "$APP_NAME"
BIN="$(swift build -c release --product "$APP_NAME" --show-bin-path)/$APP_NAME"

echo "==> Assembling $BUNDLE"
rm -rf "$BUNDLE"
mkdir -p "$BUNDLE/Contents/MacOS" "$BUNDLE/Contents/Resources"
cp "$BIN" "$BUNDLE/Contents/MacOS/$APP_NAME"
cp Resources/Info.plist "$BUNDLE/Contents/Info.plist"
printf 'APPL????' > "$BUNDLE/Contents/PkgInfo"

echo "==> Generating icon"
if swift Scripts/make-icon.swift .build >/dev/null 2>&1; then
    iconutil -c icns .build/AppIcon.iconset -o "$BUNDLE/Contents/Resources/AppIcon.icns"
else
    echo "    (icon generation failed — continuing without one)"
fi

# Ad-hoc signature. Enough for macOS to grant this bundle a stable identity for
# Automation prompts, notifications, and the login item on THIS Mac. It is not
# notarized, so another Mac would need right-click -> Open the first time.
echo "==> Signing (ad-hoc)"
codesign --force --deep --sign - --options runtime "$BUNDLE" 2>/dev/null \
    || codesign --force --deep --sign - "$BUNDLE"

if [[ "$INSTALL" == "1" ]]; then
    DEST="/Applications"
    if [[ ! -w "$DEST" ]]; then
        DEST="$HOME/Applications"
        mkdir -p "$DEST"
        echo "==> /Applications not writable, installing to $DEST instead"
    fi

    # Quit a running copy first, or the replace fails and the old binary keeps running.
    pkill -x "$APP_NAME" 2>/dev/null || true
    sleep 0.5

    rm -rf "$DEST/${APP_NAME}.app"
    cp -R "$BUNDLE" "$DEST/${APP_NAME}.app"
    echo "==> Installed $DEST/${APP_NAME}.app"
    echo "    Launch with: open \"$DEST/${APP_NAME}.app\""
else
    echo "==> Built $BUNDLE (not installed)"
fi
