#!/bin/bash
#
# Builds Pomodoro.app (with its widget extension inside) and installs it.
#
#   ./Scripts/build.sh                build + install to /Applications
#   ./Scripts/build.sh --no-install   build the bundle into .build/ only
#
# SwiftPM has no concept of an app extension, so the widget is built as an ordinary
# executable and hand-assembled into Contents/PlugIns/PomodoroWidget.appex here.
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

APP_NAME="Pomodoro"
WIDGET_NAME="PomodoroWidget"
BUNDLE=".build/${APP_NAME}.app"
APPEX="$BUNDLE/Contents/PlugIns/${WIDGET_NAME}.appex"
INSTALL=1
[[ "${1:-}" == "--no-install" ]] && INSTALL=0

echo "==> Building release binaries"
swift build -c release --product "$APP_NAME"
swift build -c release --product "$WIDGET_NAME"
BIN_DIR="$(swift build -c release --show-bin-path)"

echo "==> Assembling $BUNDLE"
rm -rf "$BUNDLE"
mkdir -p "$BUNDLE/Contents/MacOS" "$BUNDLE/Contents/Resources" "$APPEX/Contents/MacOS"
cp "$BIN_DIR/$APP_NAME" "$BUNDLE/Contents/MacOS/$APP_NAME"
cp Resources/Info.plist "$BUNDLE/Contents/Info.plist"
printf 'APPL????' > "$BUNDLE/Contents/PkgInfo"

cp "$BIN_DIR/$WIDGET_NAME" "$APPEX/Contents/MacOS/$WIDGET_NAME"
cp Resources/Widget-Info.plist "$APPEX/Contents/Info.plist"

echo "==> Generating icon"
if swift Scripts/make-icon.swift .build >/dev/null 2>&1; then
    iconutil -c icns .build/AppIcon.iconset -o "$BUNDLE/Contents/Resources/AppIcon.icns"
else
    echo "    (icon generation failed — continuing without one)"
fi

# Signing identity.
#
# This MUST be stable across rebuilds. macOS records a TCC permission (Accessibility,
# Notifications, Automation) against the app's *designated requirement*. An ad-hoc
# signature's requirement is based on the code hash, which changes on every single
# build — so every rebuild silently invalidated every permission the user had
# granted, and the media key, notifications and AppleScript all stopped working with
# no error anywhere.
#
# A real certificate produces a requirement based on identifier + certificate leaf,
# which does not change when the code does. Override with CODESIGN_IDENTITY if you
# want a different one; falls back to ad-hoc, which builds and runs fine but makes
# permissions evaporate on each rebuild.
if [[ -n "${CODESIGN_IDENTITY:-}" ]]; then
    IDENTITY="$CODESIGN_IDENTITY"
else
    IDENTITY="$(security find-identity -v -p codesigning 2>/dev/null \
        | grep -oE '"[^"]+"' | head -1 | tr -d '"')"
fi

if [[ -z "$IDENTITY" ]]; then
    IDENTITY="-"
    echo "==> Signing (ad-hoc — no certificate found)"
    echo "    WARNING: permissions will be revoked on every rebuild."
else
    echo "==> Signing as: $IDENTITY"
fi

# Order matters: nested code must be signed before the container that holds it, or
# the outer signature seals a hash that no longer matches.
codesign --force --sign "$IDENTITY" --entitlements Resources/PomodoroWidget.entitlements \
    --options runtime "$APPEX"
codesign --force --sign "$IDENTITY" --entitlements Resources/Pomodoro.entitlements \
    --options runtime "$BUNDLE"
codesign --verify --deep --strict "$BUNDLE" && echo "    signature verified"

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

    # Nudge the system to notice the widget extension. Registration normally happens
    # when Launch Services indexes the app, which a manual copy can miss.
    /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
        -f "$DEST/${APP_NAME}.app" 2>/dev/null || true
    pluginkit -a "$DEST/${APP_NAME}.app/Contents/PlugIns/${WIDGET_NAME}.appex" 2>/dev/null || true

    echo "==> Installed $DEST/${APP_NAME}.app"
    echo "    Launch with: open \"$DEST/${APP_NAME}.app\""
else
    echo "==> Built $BUNDLE (not installed)"
fi
