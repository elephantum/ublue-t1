# After sleep on inactivity, screen does not wake up

**Status:** In Progress

## Root cause

MBP14,3 (15") has both Intel iGPU (00:02.0) and AMD dGPU (01:00.0 Radeon RX 460).
The internal eDP-1 panel is driven by the AMD GPU. On resume from deep (S3) sleep, the AMD
GPU fails to reinitialize the panel — known issue documented in
[Dunedan's mbp-2016-linux guide](https://github.com/Dunedan/mbp-2016-linux#suspend--hibernation):
"The 15" models with AMD GPU only resume reliably when using the integrated Intel graphics."

## Fixes applied

### 1. Force s2idle (not deep/S3) — three layers

- `system_files/etc/systemd/sleep.conf.d/mbp14-suspend.conf` — `MemorySleepMode=s2idle`
  (already present; tells systemd to prefer s2idle)
- `system_files/usr/lib/bootc/kargs.d/mbp14-sleep.toml` — `mem_sleep_default=s2idle`
  (kernel cmdline default, applied at rebase via bootc; belt-and-suspenders)

s2idle keeps the GPU powered (CPU package C-states only), so AMD re-init is not required.

### 2. Post-resume display reset hook

`system_files/usr/lib/systemd/system-sleep/mbp14-display-reset` — runs after every resume:
- Writes `detect` to all `card*-eDP-*` connector status files (forces DRM hotplug re-scan)
- Restores backlight to 50% if it woke at 0

## Testing

After rebasing, verify:
1. `cat /sys/power/mem_sleep` shows `[s2idle] deep` (s2idle active)
2. Let screen sleep via inactivity timeout → move mouse → screen should come back
3. Manually: `sudo systemctl suspend` → wake with power button

## Notes

This fix did not help, after suspend screen remained black