# Build and test

The build is intentionally pinned to Debian **trixie** rather than the moving `stable` alias, so rebuilding the 0.1 branch does not silently switch major releases. Packages still receive current trixie security updates at build time.

On Windows with Docker Desktop available, run from a PowerShell prompt in this directory:

```powershell
docker run --rm --privileged -v "${PWD}:/src" -w /src debian:trixie sh -c "sed -i 's/^Components: main$/Components: main contrib non-free-firmware/' /etc/apt/sources.list.d/debian.sources && apt-get update && apt-get install -y live-build debootstrap debian-archive-keyring xorriso squashfs-tools grub-pc-bin grub-efi-amd64-bin mtools dosfstools shellcheck sway desktop-file-utils librsvg2-bin fonts-noto-core fontconfig python3 && sh ./scripts/build.sh"
```

The build directory needs a Linux filesystem. Docker Desktop's bind mount from NTFS may fail on Unix permissions and symlinks; for repeatable builds, clone the repository into a Debian VM or WSL Linux filesystem, or use the GitHub Actions workflow.

Check the result:

```sh
cd dist
sha256sum -c WadkOS-Developer-Preview-0.1-amd64.iso.sha256
xorriso -indev WadkOS-Developer-Preview-0.1-amd64.iso -report_el_torito plain
```

Then run `sh ./scripts/test-qemu.sh`. In QEMU, verify UEFI boot, Plymouth splash, automatic Sway session, Arabic bar/launcher, network connectivity, audio devices, and all four app launchers. A VM can lack a real audio sink; PipeWire should still start.

For physical hardware, write the ISO to a USB drive with a trusted image writer, boot it in UEFI mode, and test Wi-Fi, graphics, suspend, sound, and input before considering an installer. **Developer Preview 0.1 has no installer and does not modify internal disks.** Secure Boot is not claimed for this preview.
