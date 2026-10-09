#!/bin/sh
set -eu
lb config \
  --distribution trixie \
  --architecture amd64 \
  --binary-image iso-hybrid \
  --bootloaders 'grub-efi,syslinux' \
  --archive-areas 'main contrib non-free-firmware' \
  --debian-installer false \
  --iso-volume WADKOS_DP01 \
  --bootappend-live 'boot=live components username=user splash console=tty0 console=ttyS0,115200 systemd.show_status=1 loglevel=6'
