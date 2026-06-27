# Show full build number in GRUB

**Status:** Done

## Description

Display the complete build number in GRUB boot menu, not just the abbreviated version (e.g., "44").

## Root cause

Currently only showing a short build identifier in GRUB.

## Fixes applied

- Deleted static `system_files/usr/lib/os-release`
- `build_files/build.sh` now generates `/usr/lib/os-release` at build time using `IMAGE_NAME` and `VERSION` env vars
- `PRETTY_NAME` is set to `"<image-name> (<version>)"` (e.g., `bluefin-dx-t1 (20240627.42)`)

## Testing

1. After rebasing to a freshly built image, run `rpm-ostree status` and confirm the version string shows the full build number (e.g., `20240627.42`) rather than just `44`
2. Reboot and verify the GRUB menu entry displays the full version

## Notes

(None)
