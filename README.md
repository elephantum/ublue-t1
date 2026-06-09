# mbp14-3-bluefin

Local Bluefin-derived image project for MacBookPro14,3 with same-machine build and rebase workflow.
The local container build backend is Podman.

## What is implemented

- Base image build from `ghcr.io/ublue-os/bluefin:latest` via [Containerfile](Containerfile)
- Local build/rebase helpers via [Justfile](Justfile)
- Feature-flagged build customization in [build_files/build.sh](build_files/build.sh)
- MBP-specific files under [system_files](system_files)
  - Broadcom BCM43602 firmware config template
   - Broadcom module policy (prefer brcmfmac, blacklist conflicting modules)
  - Camera quirk (`uvcvideo`)
  - Suspend workaround service (`d3cold_allowed=0`)
  - Best-effort iBridge rebind service for Touch Bar

## Local build and rebase (same machine)

1. Build image:

   ```bash
   just build
   ```

2. Verify built tag exists:

   ```bash
   just list-images
   ```

3. Rebase to local image:

   ```bash
   just rebase-local
   sudo systemctl reboot
   ```

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

Supported flags in [build_files/build.sh](build_files/build.sh):

- `ENABLE_MBP_WIFI` (default `1`)
- `ENABLE_MBP_CAMERA` (default `1`)
- `ENABLE_MBP_SUSPEND_QUIRK` (default `1`)
- `ENABLE_MBP_TOUCHBAR_REBIND` (default `1`)

## Known constraints

- The original EFI partition is already lost, so iBridge-dependent features are best-effort.
- Touch ID is out of scope.
- Touch Bar and camera are non-blocking for stable image acceptance.
