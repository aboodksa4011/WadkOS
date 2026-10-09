#!/bin/sh
set -eu
ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
ISO="$ROOT/dist/WadkOS-Developer-Preview-0.1-amd64.iso"
[ -f "$ISO" ] || { echo "Missing ISO: $ISO" >&2; exit 1; }
command -v qemu-system-x86_64 >/dev/null || { echo 'Install qemu-system-x86.' >&2; exit 1; }
OVMF=${OVMF_CODE:-/usr/share/OVMF/OVMF_CODE_4M.fd}
VARS=${OVMF_VARS:-/usr/share/OVMF/OVMF_VARS_4M.fd}
[ -f "$OVMF" ] && [ -f "$VARS" ] || { echo 'Install ovmf or set OVMF_CODE and OVMF_VARS.' >&2; exit 1; }
VARS_COPY=$(mktemp)
trap 'rm -f "$VARS_COPY"' EXIT HUP INT TERM
cp "$VARS" "$VARS_COPY"
qemu-system-x86_64 -machine q35,accel=kvm:tcg -cpu max -m 4096 -smp 4 \
  -drive "if=pflash,format=raw,readonly=on,file=$OVMF" \
  -drive "if=pflash,format=raw,file=$VARS_COPY" \
  -cdrom "$ISO" -boot d -display gtk -vga virtio \
  -device virtio-net-pci,netdev=n0 -netdev user,id=n0
