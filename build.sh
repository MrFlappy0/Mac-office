#!/bin/bash
# Compile, package et signe Paper.app
set -euo pipefail
cd "$(dirname "$0")"

APP="Paper.app"

# Icône (générée une seule fois)
if [ ! -f src/Paper.icns ]; then
  TMP="$(mktemp -d)"
  (cd "$TMP" && swift "$OLDPWD/src/icon.swift")
  mkdir "$TMP/Paper.iconset"
  for s in 16 32 64 128 256 512; do
    sips -z "$s" "$s" "$TMP/icon_1024.png" --out "$TMP/Paper.iconset/icon_${s}x${s}.png" >/dev/null
    sips -z $((s * 2)) $((s * 2)) "$TMP/icon_1024.png" --out "$TMP/Paper.iconset/icon_${s}x${s}@2x.png" >/dev/null
  done
  iconutil -c icns "$TMP/Paper.iconset" -o src/Paper.icns
  rm -rf "$TMP"
fi

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

swiftc -O -o "$APP/Contents/MacOS/Paper" src/main.swift
cp src/editor.html "$APP/Contents/Resources/editor.html"
cp src/Paper.icns "$APP/Contents/Resources/Paper.icns"
cp src/Info.plist "$APP/Contents/Info.plist"

codesign --force --sign - "$APP" >/dev/null

echo "Build OK : $APP"
