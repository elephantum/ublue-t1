# bluefin-dx-t1

Local Bluefin-derived image project for MacBookPro14,3 with same-machine build and rebase workflow.
The local container build backend is Podman.

## What is implemented

- Default image build from `ghcr.io/ublue-os/bluefin-dx:latest` (`bluefin-dx-t1`) via [Containerfile](Containerfile); also builds `silverblue-main-t1` and `bluefin-t1`
- Local build/rebase helpers via [Justfile](Justfile)
- Feature-flagged build customization in [build_files/build.sh](build_files/build.sh)
- MBP-specific files under [system_files](system_files)
  - Broadcom BCM43602 firmware config template
   - Broadcom module policy (prefer brcmfmac, blacklist conflicting modules)
  - Camera quirk (`uvcvideo`)
   - Suspend workaround (`s2idle` plus `d3cold_allowed=0`)
  - Best-effort iBridge rebind service for Touch Bar

## Local build and rebase (same machine)

1. Build image:

   ```bash
   just build
   ```

   This writes the generated build tag to `.just-build-tag` and tags the image
   with a unique build number, so each build gets its own rebase target.

2. Verify built tag exists:

   ```bash
   just list-images
   ```

3. Rebase to local image:

   ```bash
   just rebase-local
   sudo systemctl reboot
   ```

   `just rebase-local` uses the most recent recorded build tag instead of the
   generic `local` tag.

4. If the deployment is bad, rollback:

   ```bash
   just rollback
   sudo systemctl reboot
   ```

5. Check deployment history:

   ```bash
   just status
   ```

## Optional build-time flags

Set flags at build time to disable risky components quickly:

```bash
ENABLE_MBP_TOUCHBAR_REBIND=0 ENABLE_MBP_CAMERA=0 just build
```

Touch Bar driver build runs in a separate Containerfile layer by default. You can
disable that layer or override the DKMS repo:

```bash
ENABLE_MBP_TOUCHBAR_DKMS_LAYER=0 just build
MBP_TOUCHBAR_DKMS_REPO=https://github.com/<owner>/<repo>.git just build
MBP_TOUCHBAR_DKMS_BRANCH=<branch> just build
```

Default pinned source is `https://github.com/roadrunner2/macbook12-spi-driver.git`
with branch `touchbar-driver-hid-driver`.

Supported flags in [build_files/build.sh](build_files/build.sh):

- `ENABLE_MBP_WIFI` (default `1`)
- `ENABLE_MBP_CAMERA` (default `1`)
- `ENABLE_MBP_SUSPEND_QUIRK` (default `1`)
- `ENABLE_MBP_TOUCHBAR_REBIND` (default `1`)

Containerfile-specific flags:

- `ENABLE_MBP_TOUCHBAR_DKMS_LAYER` (default `1`)
- `MBP_TOUCHBAR_DKMS_REPO` (default `https://github.com/roadrunner2/macbook12-spi-driver.git`)
- `MBP_TOUCHBAR_DKMS_BRANCH` (default `touchbar-driver-hid-driver`)

## Known constraints

- The original EFI partition is already lost, so iBridge-dependent features are best-effort.
- Touch ID is out of scope.
- Touch Bar and camera are non-blocking for stable image acceptance.
