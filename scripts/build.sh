#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
BUILD="$ROOT/build"
DIST="$ROOT/dist"
ISO_NAME=WadkOS-Developer-Preview-0.1-amd64.iso

[ "$(uname -s)" = Linux ] || { echo 'Build requires Linux.' >&2; exit 1; }
[ "$(id -u)" -eq 0 ] || { echo 'Run as root: sudo ./scripts/build.sh' >&2; exit 1; }
command -v lb >/dev/null || { echo 'Install Debian live-build.' >&2; exit 1; }
command -v debootstrap >/dev/null || { echo 'Install debootstrap.' >&2; exit 1; }
sh "$ROOT/scripts/check-build.sh"

mkdir -p "$BUILD" "$DIST"
cd "$BUILD"
sh "$ROOT/scripts/configure.sh"

cp -a "$ROOT/live/config/." "$BUILD/config/"
mkdir -p "$BUILD/config/includes.chroot/usr/share/plymouth/themes/wadk" "$BUILD/config/includes.chroot/usr/share/wadkos"
rsvg-convert -w 1920 -h 1080 -o "$BUILD/config/includes.chroot/usr/share/plymouth/themes/wadk/background.png" "$ROOT/art/boot-background.svg"
rsvg-convert -w 950 -h 250 -o "$BUILD/config/includes.chroot/usr/share/plymouth/themes/wadk/logo.png" "$ROOT/art/boot-logo.svg"
rsvg-convert -w 1920 -h 1080 -o "$BUILD/config/includes.chroot/usr/share/wadkos/wallpaper.png" "$ROOT/art/wallpaper.svg"
chmod 0755 "$BUILD"/config/hooks/live/*.hook.chroot
if ! lb build > "$DIST/build.log" 2>&1; then
  tail -n 100 "$DIST/build.log" >&2
  exit 1
fi
tail -n 20 "$DIST/build.log"

test -s live-image-amd64.hybrid.iso || { echo 'live-build did not produce an ISO.' >&2; exit 1; }
cp live-image-amd64.hybrid.iso "$DIST/$ISO_NAME"
cd "$DIST"
sha256sum "$ISO_NAME" > "$ISO_NAME.sha256"
echo "Built $DIST/$ISO_NAME"
