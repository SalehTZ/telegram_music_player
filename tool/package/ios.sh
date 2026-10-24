#!/usr/bin/env bash
# Packs the iOS app as an unsigned .ipa:
#
#   flutter build ios --release --no-codesign
#   tool/package/ios.sh
#
# Without an Apple developer account nothing can sign it here, so it has to be
# signed while sideloading (AltStore, Sideloadly) or on a jailbroken device.
set -euo pipefail

DIST="$PWD/dist"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$DIST" "$WORK/Payload"

cp -R build/ios/iphoneos/Runner.app "$WORK/Payload/"
(cd "$WORK" && zip -qry "$DIST/stash-ios-unsigned.ipa" Payload)

ls -l "$DIST"
