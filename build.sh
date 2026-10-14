#!/bin/bash
# Compile, package et signe MinWord.app
set -euo pipefail
cd "$(dirname "$0")"

APP="MinWord.app"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

swiftc -O -o "$APP/Contents/MacOS/MinWord" src/main.swift
cp src/editor.html "$APP/Contents/Resources/editor.html"
cp src/Info.plist "$APP/Contents/Info.plist"

codesign --force --sign - "$APP" >/dev/null

echo "Build OK : $APP"
