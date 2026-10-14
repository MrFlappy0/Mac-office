#!/bin/bash
# Compile Paper (Swift Package Manager), assemble le .app, signe et construit le DMG.
# Le numéro de version vient du fichier VERSION.
set -euo pipefail
cd "$(dirname "$0")"

VERSION="$(tr -d '[:space:]' < VERSION)"
APP="Paper.app"
DMG="Paper-${VERSION}.dmg"

# Icône : générée par CoreGraphics si absente (compatible runners CI sans affichage)
if [ ! -f Resources/Paper.icns ]; then
  TMP="$(mktemp -d)"
  (cd "$TMP" && swift "$OLDPWD/Scripts/make-icon.swift")
  mkdir "$TMP/Paper.iconset"
  for s in 16 32 64 128 256 512; do
    sips -z "$s" "$s" "$TMP/icon_1024.png" --out "$TMP/Paper.iconset/icon_${s}x${s}.png" >/dev/null
    sips -z $((s * 2)) $((s * 2)) "$TMP/icon_1024.png" --out "$TMP/Paper.iconset/icon_${s}x${s}@2x.png" >/dev/null
  done
  iconutil -c icns "$TMP/Paper.iconset" -o Resources/Paper.icns
  rm -rf "$TMP"
fi

swift build -c release

rm -rf "$APP" "$DMG"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

cp .build/release/Paper "$APP/Contents/MacOS/Paper"
cp Resources/editor.html "$APP/Contents/Resources/editor.html"
cp Resources/Paper.icns "$APP/Contents/Resources/Paper.icns"
cp Resources/Info.plist "$APP/Contents/Info.plist"

/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString ${VERSION}" "$APP/Contents/Info.plist" >/dev/null
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${VERSION}" "$APP/Contents/Info.plist" >/dev/null

codesign --force --sign - "$APP" >/dev/null

hdiutil create -volname "Paper" -srcfolder "$APP" -ov -format UDZO "$DMG" >/dev/null

echo "Build OK : $APP et $DMG (version ${VERSION})"
