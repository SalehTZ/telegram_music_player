#!/usr/bin/env bash
# Packs the macOS app as a .dmg and a .zip:
#
#   flutter build macos --release
#   tool/package/macos.sh
#
# The app is universal (Apple silicon and Intel) and signed ad hoc, not by a
# registered developer, so the first launch needs right-click > Open.
set -euo pipefail

APP=build/macos/Build/Products/Release/Stash.app
DIST="$PWD/dist"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$DIST"

ditto -c -k --sequesterRsrc --keepParent "$APP" "$DIST/stash-macos.zip"

# * The usual drag-to-Applications window
mkdir "$WORK/Stash"
cp -R "$APP" "$WORK/Stash/"
ln -s /Applications "$WORK/Stash/Applications"
hdiutil create -volname Stash -srcfolder "$WORK/Stash" -fs HFS+ \
  -format UDZO -ov "$DIST/stash-macos.dmg"

ls -l "$DIST"
