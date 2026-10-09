#!/bin/sh
set -eu
ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
ISO="$ROOT/dist/WadkOS-Developer-Preview-0.1-amd64.iso"
LOG="$ROOT/dist/qemu-boot.log"
[ -s "$ISO" ] || { echo "Missing ISO: $ISO" >&2; exit 1; }
command -v qemu-system-x86_64 >/dev/null || { echo 'Install qemu-system-x86.' >&2; exit 1; }
command -v timeout >/dev/null || { echo 'Install coreutils.' >&2; exit 1; }
OVMF_CODE=${OVMF_CODE:-/usr/share/OVMF/OVMF_CODE_4M.fd}
OVMF_VARS=${OVMF_VARS:-/usr/share/OVMF/OVMF_VARS_4M.fd}
[ -f "$OVMF_CODE" ] && [ -f "$OVMF_VARS" ] || { echo 'Install ovmf or set OVMF_CODE and OVMF_VARS.' >&2; exit 1; }
VARS_COPY=$(mktemp)
trap 'rm -f "$VARS_COPY"' EXIT HUP INT TERM
cp "$OVMF_VARS" "$VARS_COPY"
rm -f "$LOG"
set +e
timeout 240 qemu-system-x86_64 -machine q35,accel=kvm:tcg -cpu max -m 3072 -smp 2 \
  -drive "if=pflash,format=raw,readonly=on,file=$OVMF_CODE" \
  -drive "if=pflash,format=raw,file=$VARS_COPY" \
  -cdrom "$ISO" -boot d -display none -vga virtio -serial "file:$LOG" \
  -monitor none -no-reboot -device virtio-net-pci,netdev=n0 -netdev user,id=n0
status=$?
set -e
[ "$status" -eq 124 ] || { echo "QEMU exited unexpectedly: $status" >&2; tail -n 80 "$LOG" >&2; exit 1; }
grep -q 'Linux version' "$LOG" || { echo 'Kernel boot not seen on serial console.' >&2; exit 1; }
grep -Eq 'Reached target.*Graphical|graphical.target' "$LOG" || { echo 'Graphical target not reached.' >&2; tail -n 80 "$LOG" >&2; exit 1; }
echo "UEFI, kernel and systemd graphical target reached. Log: $LOG"
