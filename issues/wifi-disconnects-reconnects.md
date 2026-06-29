# Wifi disconnects and reconnects periodically

**Status:** In Progress

## Root cause

The `brcmf_msgbuf_delete_flowring: timed out waiting for txstatus` error causes the driver to force a reset every ~65 seconds, triggering the disconnect cycle. This is a firmware bug in the generic BCM43602 firmware (Nov 2015) that ships with linux-firmware.

The Apple-specific firmware `brcm/brcmfmac43602-pcie.Apple Inc.-MacBookPro14,3.bin` (plus CLM blob and txcap blob) is missing. The driver falls back to generic firmware which has the flowring timeout bug. linux-firmware 20260519 (latest) still does not include the Apple blob.

Signal strength is excellent (-38 dBm), so RF is not the issue.

## Fixes tried

- **`options brcmfmac power_save=0`** — invalid parameter (kernel: `unknown parameter 'power_save' ignored`). Removed.

## Fixes applied

1. **`roamoff=1`** in modprobe config: Disables driver's internal roaming engine.
2. **MBP14,3-specific NVRAM calibration** in `brcmfmac43602-pcie.txt`: Replaced generic linux-firmware calibration with MBP14,3-tuned parameters from takiido/mbp14.3-linux repo. Includes RF tuning, PA parameters, and BT coexistence settings.

## Testing

1. After applying a fix, monitor for disconnects:
   ```
   journalctl -f -u NetworkManager | grep -i "disconnect\|completed"
   ```
2. Wait at least 5 minutes — with the current pattern, 3+ disconnects should occur within that window if unfixed.
3. Confirm no `brcmf_msgbuf_delete_flowring: timed out` in `journalctl -k`.
