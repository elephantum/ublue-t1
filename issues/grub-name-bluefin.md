# Image name shown as Bluefin in GRUB

**Status:** Done

## Fix

Added `system_files/usr/lib/os-release` with `NAME="ublue-t1"` and `PRETTY_NAME="ublue-t1 44"`. The `COPY system_files/ /` in the Containerfile overwrites the base image's os-release, which is what GRUB reads for the boot menu entry.
