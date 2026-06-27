# ublue-t1

Custom Universal Blue images for **MacBookPro14,3** (2017 15-inch with T1 chip).

Built on top of [Universal Blue](https://universal-blue.org/) / Fedora Silverblue, with hardware quirks baked in so things work out of the box.

## Hardware compatibility

| Feature | Status | Notes |
|---------|--------|-------|
| WiFi (BCM43602) | Works | firmware config + module policy included |
| Camera (FaceTime HD) | Works | requires macOS EFI partition to be intact |
| Touch Bar | Works | iBridge rebind service + DKMS driver |
| Suspend/resume | Mostly works | s2idle + d3cold quirk; screen occasionally doesn't wake |
| Sound in browser | Broken | not yet resolved |
| Touch ID | Not supported | out of scope |

## Quick start

Pick the image variant closest to your preference and rebase to it:

```bash
# Silverblue (vanilla GNOME)
sudo rpm-ostree rebase ostree-unverified-image:docker://ghcr.io/elephantum/silverblue-main-t1:latest

# Bluefin (developer-friendly GNOME)
sudo rpm-ostree rebase ostree-unverified-image:docker://ghcr.io/elephantum/bluefin-t1:latest

# Bluefin DX (Bluefin + full dev toolbox)
sudo rpm-ostree rebase ostree-unverified-image:docker://ghcr.io/elephantum/bluefin-dx-t1:latest
```

Then reboot. That's it.

To check which image you're running and its build number:

```bash
rpm-ostree status
```

## What's included

All variants ship the same hardware fix layer on top of the base image:

- **WiFi**: Broadcom BCM43602 firmware config and module policy (`brcmfmac` preferred, conflicting modules blacklisted)
- **Camera**: `uvcvideo` quirk for the iBridge UVC interface
- **Touch Bar**: `mbp-ibridge-rebind` service that re-enumerates iBridge at boot and rebinds the HID display interface from `hid-sensor-hub` to `apple-ibridge-hid`, activating the touchbar driver
- **Suspend**: `s2idle` sleep mode + `d3cold_allowed=0` workaround to prevent hangs on suspend/resume

## Building locally

If you want to customize the image or iterate on hardware fixes:

```bash
git clone https://github.com/elephantum/ublue-t1
cd ublue-t1
just build          # builds bluefin-dx-t1 by default
just rebase-local   # rebases to the freshly built image
sudo systemctl reboot
```

If the new image is bad:

```bash
just rollback
sudo systemctl reboot
```

### Build-time flags

Disable specific components to isolate issues:

```bash
ENABLE_MBP_WIFI=0 just build
ENABLE_MBP_CAMERA=0 just build
ENABLE_MBP_SUSPEND_QUIRK=0 just build
ENABLE_MBP_TOUCHBAR_REBIND=0 just build

# Disable or override the touchbar DKMS kernel module build
ENABLE_MBP_TOUCHBAR_DKMS_LAYER=0 just build
MBP_TOUCHBAR_DKMS_REPO=https://github.com/<fork>.git just build
MBP_TOUCHBAR_DKMS_BRANCH=<branch> just build
```

Default touchbar driver source: `https://github.com/nanachi2002/macbook12-spi-driver.git`, branch `fix/kernel-6.17-compat`.
