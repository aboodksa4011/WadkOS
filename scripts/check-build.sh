#!/bin/sh
set -eu
ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
INCLUDE="$ROOT/live/config/includes.chroot"

fail() { echo "Prebuild check failed: $*" >&2; exit 1; }
for tool in lb debootstrap apt-cache desktop-file-validate rsvg-convert python3 shellcheck sway fc-match; do
    command -v "$tool" >/dev/null 2>&1 || fail "Missing build tool: $tool"
done

for file in \
    "$ROOT/scripts/build.sh" "$ROOT/scripts/configure.sh" "$ROOT/scripts/check-build.sh" \
    "$ROOT/scripts/test-qemu.sh" "$ROOT/scripts/test-qemu-boot.sh" \
    "$ROOT/live/config/package-lists/wadkos.list.chroot" \
    "$ROOT/live/config/hooks/live/010-wadkos.hook.chroot" \
    "$INCLUDE/etc/sway/config" "$INCLUDE/etc/xdg/waybar/config.jsonc" \
    "$INCLUDE/etc/skel/.profile" "$INCLUDE/usr/local/bin/wadk-session" \
    "$INCLUDE/usr/local/bin/wadk-settings" "$INCLUDE/usr/local/bin/wadk-files" \
    "$INCLUDE/usr/local/bin/wadk-terminal" "$INCLUDE/usr/local/bin/wadk-monitor" \
    "$INCLUDE/usr/share/plymouth/themes/wadk/wadk.plymouth" \
    "$ROOT/art/boot-background.svg" "$ROOT/art/boot-logo.svg" "$ROOT/art/wallpaper.svg"; do
    [ -s "$file" ] || fail "Missing or empty file: $file"
done

for file in "$ROOT"/scripts/*.sh "$ROOT"/live/config/hooks/live/*.hook.chroot "$INCLUDE"/usr/local/bin/wadk-*; do
    [ -x "$file" ] || fail "Script is not executable: $file"
    case "$(head -n 1 "$file")" in '#!'*) ;; *) fail "Missing shebang: $file" ;; esac
    case "$(head -n 1 "$file")" in *python3*) python3 - "$file" <<'PY'
import ast, pathlib, sys
ast.parse(pathlib.Path(sys.argv[1]).read_text(encoding='utf-8'))
PY
        ;; *) sh -n "$file" || fail "Shell syntax: $file"
              shellcheck -S warning "$file" || fail "ShellCheck: $file" ;; esac
done
sh -n "$INCLUDE/etc/skel/.profile" || fail 'Invalid login profile'
sway -C -c "$INCLUDE/etc/sway/config" >/dev/null 2>&1 || fail 'Invalid Sway config'
fc-match -f '%{family}\n' 'Noto Sans Arabic' | grep -q 'Noto Sans Arabic' || fail 'Noto Sans Arabic is unavailable on build host'
fc-match -f '%{family}\n' 'Noto Sans' | grep -q 'Noto Sans' || fail 'Noto Sans is unavailable on build host'
[ -z "$(find "$ROOT" -type f \( -iname '*.ttf' -o -iname '*.otf' -o -iname '*.woff*' \) -print -quit)" ] || fail 'Font file embedded in source tree'

for file in "$INCLUDE"/usr/share/applications/wadk-*.desktop "$INCLUDE"/usr/share/wayland-sessions/wadkos.desktop; do
    desktop-file-validate "$file" || fail "Invalid desktop entry: $file"
done

python3 - "$ROOT" <<'PY'
from pathlib import Path
import json, sys, xml.etree.ElementTree as ET
root = Path(sys.argv[1])
inc = root / 'live/config/includes.chroot'
json.loads((inc / 'etc/xdg/waybar/config.jsonc').read_text(encoding='utf-8'))
for svg in (root / 'art').glob('*.svg'):
    ET.parse(svg)
locale = (inc / 'etc/default/locale').read_text()
assert 'LANG=ar_SA.UTF-8' in locale
generated = (inc / 'etc/locale.gen').read_text()
assert 'ar_SA.UTF-8 UTF-8' in generated and 'en_US.UTF-8 UTF-8' in generated
packages = (root / 'live/config/package-lists/wadkos.list.chroot').read_text()
assert 'fonts-noto-core' in packages and 'linux-image-amd64' in packages
for entry in (inc / 'usr/share/applications').glob('wadk-*.desktop'):
    command = next(line[5:].split()[0] for line in entry.read_text().splitlines() if line.startswith('Exec='))
    assert (inc / 'usr/local/bin' / command).is_file(), (entry, command)
PY

PACKAGES="$ROOT/live/config/package-lists/wadkos.list.chroot"
while IFS= read -r package || [ -n "$package" ]; do
    case "$package" in ''|'#'*) continue ;; esac
    apt-cache show "$package" >/dev/null 2>&1 || fail "Package unavailable in configured APT sources: $package"
done < "$PACKAGES"

TEMP=$(mktemp -d)
trap 'rm -rf "$TEMP"' EXIT HUP INT TERM
(cd "$TEMP" && sh "$ROOT/scripts/configure.sh" && lb config --validate) >/dev/null || fail 'Invalid live-build config'
echo 'Prebuild checks passed.'
