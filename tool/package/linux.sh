#!/usr/bin/env bash
# Packs the Linux release bundle as a tarball, a .deb and an AppImage:
#
#   flutter build linux --release
#   VERSION=0.3.0 tool/package/linux.sh
#
# Everything lands in dist/. The AppImage brings its own libmpv; the tarball
# and the .deb use the system one (libmpv2 or libmpv1).
set -euo pipefail

VERSION="${VERSION:-$(sed -n 's/^version: *\([^+]*\).*/\1/p' pubspec.yaml)}"
BUNDLE="$PWD/build/linux/x64/release/bundle"
ASSETS="$PWD/linux/packaging"
APP_ID=ir.salehtz.stash
DIST="$PWD/dist"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$DIST"

# * tar.gz: the bundle as is, with the desktop entry and icon beside it
mkdir "$WORK/stash"
cp -r "$BUNDLE"/. "$WORK/stash/"
cp "$ASSETS/$APP_ID.desktop" "$ASSETS/$APP_ID.png" "$WORK/stash/"
tar -C "$WORK" -czf "$DIST/stash-linux-x64.tar.gz" stash

# * deb: the bundle in /opt/stash, linked from /usr/bin
DEB="$WORK/deb"
mkdir -p "$DEB/DEBIAN" "$DEB/opt/stash" "$DEB/usr/bin" \
  "$DEB/usr/share/applications" "$DEB/usr/share/icons/hicolor/512x512/apps"
cp -r "$BUNDLE"/. "$DEB/opt/stash/"
ln -s /opt/stash/stash "$DEB/usr/bin/stash"
cp "$ASSETS/$APP_ID.desktop" "$DEB/usr/share/applications/"
cp "$ASSETS/$APP_ID.png" "$DEB/usr/share/icons/hicolor/512x512/apps/"
cat > "$DEB/DEBIAN/control" <<CONTROL
Package: stash
Version: ${VERSION}
Architecture: amd64
Maintainer: SalehTZ <31685655+SalehTZ@users.noreply.github.com>
Installed-Size: $(du -sk "$DEB" | cut -f1)
Depends: libgtk-3-0t64 | libgtk-3-0, libmpv2 | libmpv1
Section: sound
Priority: optional
Homepage: https://github.com/SalehTZ/Stash
Description: Music player for the songs you collect on Telegram
 Plays, tags and tidies the music in your Music and Telegram Desktop
 download folders.
CONTROL
dpkg-deb --root-owner-group -Zxz --build "$DEB" "$DIST/stash-linux-amd64.deb"

# * AppImage: linuxdeploy copies libmpv and what it needs next to the app.
# Flutter finds lib/ and data/ beside its executable, so the bundle stays
# whole in usr/bin and the libraries go to usr/lib.
TOOLS="$WORK/tools"
mkdir -p "$TOOLS"
for tool in linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage \
  linuxdeploy-plugin-appimage/releases/download/continuous/linuxdeploy-plugin-appimage-x86_64.AppImage; do
  curl -fsSL -o "$TOOLS/${tool##*/}" "https://github.com/linuxdeploy/$tool"
done
curl -fsSL -o "$TOOLS/linuxdeploy-plugin-gtk.sh" \
  https://raw.githubusercontent.com/linuxdeploy/linuxdeploy-plugin-gtk/master/linuxdeploy-plugin-gtk.sh
chmod +x "$TOOLS"/*

APPDIR="$WORK/Stash.AppDir"
mkdir -p "$APPDIR/usr/bin"
cp -r "$BUNDLE"/. "$APPDIR/usr/bin/"
LIBMPV=$(ldconfig -p | awk '/libmpv\.so\.[12] /{print $NF; exit}')

export PATH="$TOOLS:$PATH" ARCH=x86_64 APPIMAGE_EXTRACT_AND_RUN=1 \
  LINUXDEPLOY_OUTPUT_VERSION="$VERSION" DEPLOY_GTK_VERSION=3 \
  LDAI_OUTPUT="$DIST/stash-linux-x86_64.AppImage" \
  LDAI_UPDATE_INFORMATION="gh-releases-zsync|SalehTZ|Stash|latest|stash-linux-x86_64.AppImage.zsync"
deploy() {
  (cd "$WORK" && linuxdeploy-x86_64.AppImage --appdir "$APPDIR" "$@")
}
deploy --executable "$APPDIR/usr/bin/stash" \
  --library "$LIBMPV" \
  --desktop-file "$ASSETS/$APP_ID.desktop" \
  --icon-file "$ASSETS/$APP_ID.png" \
  --plugin gtk
# linuxdeploy copied the engine and plugin to usr/lib and pointed the
# executable there, so the copies in the bundle are dead weight
for lib in "$APPDIR"/usr/bin/lib/*.so; do
  [ -e "$APPDIR/usr/lib/${lib##*/}" ] && rm "$lib"
done
# media_kit asks for libmpv.so before libmpv.so.2, so name ours that too,
# or a system copy from libmpv-dev wins
ln -sf "${LIBMPV##*/}" "$APPDIR/usr/lib/libmpv.so"
deploy --output appimage
mv "$WORK"/*.zsync "$DIST/" 2>/dev/null || true

ls -l "$DIST"
