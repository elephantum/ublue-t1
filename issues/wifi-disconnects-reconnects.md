# Wifi disconnects and reconnects periodically

**Status:** Backlog

## Root cause

Multiple contributing factors identified from logs and driver state:

1. **Missing Apple-specific firmware**: The `brcmfmac` driver (BCM43602) fails to load the device-specific firmware blob `brcm/brcmfmac43602-pcie.Apple Inc.-MacBookPro14,3.bin` and falls back to generic firmware dated Nov 2015. The CLM blob (`brcmfmac43602-pcie.clm_blob`) and txcap blob also fail to load, which limits channel availability and may reduce stability.

2. **Firmware timeouts**: Kernel logs show `brcmf_msgbuf_delete_flowring: timed out waiting for txstatus`, indicating the firmware is hanging during flow ring cleanup — a known instability symptom with brcmfmac on Apple hardware.

3. **Wifi power management enabled**: The brcmfmac `power_save` parameter is set to `10`. This can cause the firmware to drop the association while aggressively power-saving, triggering the periodic reconnect cycle.

Observed behavior: disconnects happen every ~60–70 seconds (23:42:50, 23:43:56, 23:45:02 in today's logs), reconnects take ~3 seconds. Signal strength is excellent (-38 dBm) so RF is not the issue.

## Fixes to try

1. **Disable wifi power management** (quickest to test):
   ```
   sudo iw dev wlp3s0 set power_save off
   ```
   Or persistently via NetworkManager: add `wifi.powersave = 2` to the connection profile.

2. **Install Apple firmware blobs**: The `linux-firmware` package or the `linux-firmware-whence` may have updated brcmfmac firmware. Alternatively, firmware can be extracted from macOS. Check if a newer `linux-firmware` update is available in Fedora repos.

3. **Disable brcmfmac power_save at module level**: Create `/etc/modprobe.d/brcmfmac.conf` with:
   ```
   options brcmfmac power_save=0
   ```

## Testing

1. After applying a fix, monitor for disconnects:
   ```
   journalctl -f -u NetworkManager | grep -i "disconnect\|completed"
   ```
2. Wait at least 5 minutes — with the current pattern, 3+ disconnects should occur within that window if unfixed.
3. Confirm no `brcmf_msgbuf_delete_flowring: timed out` in `journalctl -k`.
