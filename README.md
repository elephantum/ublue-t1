# ublue-t1

Custom Universal Blue images for **MacBookPro14,3** (2017 15-inch with T1 chip).

Built on top of [Universal Blue](https://universal-blue.org/) / Fedora Silverblue, with hardware quirks baked in so things work out of the box.

## Hardware compatibility

| Feature | Status | Notes |
|---------|--------|-------|
| WiFi (BCM43602) | Works | firmware config + module policy, plus a regdomain fix for periodic disconnects — [details](issues/wifi-disconnects-reconnects.md) |
| Camera (FaceTime HD) | Works | requires macOS EFI partition to be intact — [details](issues/camera-not-visible.md) |
| Touch Bar | Works | iBridge rebind service + DKMS driver — [details](issues/touchbar-dark-inactive.md) |
| Suspend/resume | Disabled | resume was unreliable and could hang the machine, so sleep is disabled entirely rather than risk it — [details](issues/sleep-screen-no-wake.md) |
| Sound | Works | custom Cirrus CS8409 codec driver (davidjo/snd_hda_macbookpro) — [details](issues/sound-no-audio.md) |
| Touch ID | Not supported | no known Linux driver for the T1 secure enclave — [details](issues/touch-id-not-working.md) |
| Display (horizontal lines) | Mitigation applied | `mbpfan` daemon ramps fans up earlier (60-65°C) to reduce heat at the hinge/display cable — [details](issues/screen-horizontal-lines.md) |

## Quick start

Only the **Bluefin DX** variant is currently built and published by CI:

```bash
sudo rpm-ostree rebase ostree-unverified-image:docker://ghcr.io/elephantum/bluefin-dx-t1:latest
```

Then reboot. That's it.

Silverblue and plain Bluefin variants are still defined in the [Containerfile](Containerfile) and the [build workflow](.github/workflows/build.yml)'s matrix, but those matrix entries are currently commented out and not published to `ghcr.io` — see [details](issues/build-multiple-images.md). Use [Building locally](#building-locally) below if you want one of them.

To check which image you're running and its build number:

```bash
rpm-ostree status
```

## What's included

All variants ship the same hardware fix layer on top of the base image:

- **WiFi**: Broadcom BCM43602 firmware config and module policy (`brcmfmac` preferred, conflicting modules blacklisted), plus a NetworkManager dispatcher script that fixes periodic 5GHz disconnects caused by a regulatory-domain mismatch ([issue](issues/wifi-disconnects-reconnects.md))
- **Camera**: `uvcvideo` quirk for the iBridge UVC interface ([issue](issues/camera-not-visible.md))
- **Touch Bar**: `mbp-ibridge-rebind` service that re-enumerates iBridge at boot and rebinds the HID display interface from `hid-sensor-hub` to `apple-ibridge-hid`, activating the touchbar driver ([issue](issues/touchbar-dark-inactive.md))
- **Suspend**: disabled entirely via `systemd-sleep` (`AllowSuspend=no` and friends) because resume reliably left the machine hung; NVMe `d3cold_allowed=0` is also set at boot as a lingering stability precaution ([issue](issues/sleep-screen-no-wake.md))
- **Sound**: Custom Cirrus CS8409 codec driver with Apple MacBook Pro amplifier support ([issue](issues/sound-no-audio.md))
- **GRUB identity**: `os-release` is generated at build time so `rpm-ostree status` and the GRUB menu show the real image name and full build number instead of generic Bluefin/short-version labels ([issue](issues/grub-name-bluefin.md), [issue](issues/grub-full-build-number.md))
- **Fan control**: `mbpfan` daemon (built from source, no kernel module needed) ramps fans up starting at 60°C instead of waiting for the stock Linux thermal curve, to reduce sustained heat at the display hinge ([issue](issues/screen-horizontal-lines.md))

## Building locally

If you want to customize the image or iterate on hardware fixes:

```bash
git clone https://github.com/elephantum/ublue-t1
cd ublue-t1
just build          # builds from the bluefin-dx base image, tagged locally as mbp14-3-bluefin
just rebase-local   # rebases to the freshly built image
sudo systemctl reboot
```

If the new image is bad:

```bash
just rollback
sudo systemctl reboot
```

### Touchbar driver source

Default touchbar driver source: `https://github.com/nanachi2002/macbook12-spi-driver.git`, branch `fix/kernel-6.17-compat`.

Override at build time:

```bash
MBP_TOUCHBAR_DKMS_REPO=https://github.com/<fork>.git just build
MBP_TOUCHBAR_DKMS_BRANCH=<branch> just build
```

### Audio driver source

Default audio driver source: `https://github.com/davidjo/snd_hda_macbookpro.git`, branch `master`.

Override at build time:

```bash
MBP_AUDIO_DKMS_REPO=https://github.com/<fork>.git just build
MBP_AUDIO_DKMS_BRANCH=<branch> just build
```

### Fan daemon source

Default fan daemon source: `https://github.com/linux-on-mac/mbpfan.git`, branch `master`.

Override at build time:

```bash
MBP_FAN_DAEMON_REPO=https://github.com/<fork>.git just build
MBP_FAN_DAEMON_BRANCH=<branch> just build
```
