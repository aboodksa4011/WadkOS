# WadkOS Developer Preview 0.1

WadkOS is an independent Debian 13 (trixie) based live desktop for amd64/UEFI, by BODKA. This repository builds a bootable hybrid ISO with Debian `live-build`. The first desktop uses the Sway Wayland compositor, a Wadk branded Waybar shell, and working Debian applications.

## Build

Build on **Debian 13 amd64**, in a disposable VM or container, with at least 12 GB free disk and 4 GB RAM:

```sh
sudo apt update
sudo apt install live-build debootstrap debian-archive-keyring xorriso squashfs-tools grub-pc-bin grub-efi-amd64-bin mtools dosfstools shellcheck sway desktop-file-utils librsvg2-bin fonts-noto-core fontconfig python3
sudo sh ./scripts/build.sh
```

The script runs `scripts/check-build.sh`, renders artwork using Debian's Noto fonts, then writes `dist/WadkOS-Developer-Preview-0.1-amd64.iso` and its SHA-256 file. It refuses to run on a non-Linux host or without root. The APT sources used for preflight must enable `main contrib non-free-firmware`. To build from Windows, use the Debian container described in `docs/BUILD.md`, or the included GitHub Actions workflow.

## Run in QEMU

Install `qemu-system-x86` and `ovmf` on the Debian host, then:

```sh
sh ./scripts/test-qemu.sh
```

The ISO boots a live session automatically on tty1. Open apps from the Arabic top bar or press `Super+D`. Shortcuts: `Super+Return` terminal, `Super+E` files, `Super+Shift+S` settings, `Super+Shift+M` monitor. The live user is `user`.

## Components

- Debian Stable 13, Linux kernel (`linux-image-amd64`), systemd, live-boot/live-config
- UEFI GRUB boot, hybrid ISO; BIOS Syslinux included for development convenience
- Sway Wayland session, Xwayland compatibility, Wadk Shell (Waybar + Wofi), Wadk Desktop wallpaper and shortcuts
- Wadk Settings: live GTK control center for display, network, audio, themes and power
- Wadk Files: Thunar; Wadk Terminal: foot; Wadk Monitor: GNOME System Monitor
- NetworkManager, PipeWire, WirePlumber, Bluetooth tools, Arabic fonts and locale
- Wadk Boot Plymouth theme and WadkOS system identity

The desktop applications are functional upstream programs with Wadk launchers. A native compositor and native replacements for Files/Terminal/Monitor are future work. The first release is a **live developer preview**; installed-system support and real-hardware compatibility are not yet validated.

## Source and licensing

Debian source packages can be explored at [Debian Sources](https://sources.debian.org/); it is a source browser, not the build mirror. This build downloads binary packages from Debian archives. Debian package licenses remain their own. Original WadkOS configuration, artwork and scripts in this repository are MIT licensed; see `LICENSE`. WadkOS is independent of and not endorsed by Debian.
