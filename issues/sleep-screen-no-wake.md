# After sleep on inactivity, screen does not wake up

**Status:** In Progress

## Root cause

MBP14,3 (15") has Intel iGPU (00:02.0) and AMD dGPU (01:00.0 Radeon RX 460).
The internal eDP-1 panel is driven by the AMD GPU. On resume, the AMD GPU fails to
reinitialize the panel — known issue per Dunedan's guide:
"The 15" models with AMD GPU only resume reliably when using the integrated Intel graphics."

## Fixes applied

### Attempt 1 — s2idle + connector detect (did not help)

- `system_files/etc/systemd/sleep.conf.d/mbp14-suspend.conf` — `MemorySleepMode=s2idle`
- `system_files/usr/lib/bootc/kargs.d/mbp14-sleep.toml` — `mem_sleep_default=s2idle`
- `system_files/usr/lib/systemd/system-sleep/mbp14-display-reset` — `echo detect` to eDP
  connector + backlight restore

### Attempt 2 — AMD runtime PM off + VT bounce + gnome-shell reload

Added `amdgpu.runpm=0` to kargs — disables AMD GPU runtime power gating during s2idle
so the GPU stays fully powered and does not need to reinitialize its display engine on wake.

Updated sleep hook (`mbp14-display-reset`) with three additional recovery steps run 2s
after wake:
1. **VT bounce** (`chvt` away and back) — forces kernel DRM to re-render the active display
2. **`pkill -USR2 gnome-shell`** — restarts gnome-shell in-place without losing the session,
   unsticks a compositor that lost track of its outputs
3. Backlight restore (kept from attempt 1)

## Testing

After rebasing:
1. `cat /proc/cmdline` — confirm `mem_sleep_default=s2idle` and `amdgpu.runpm=0` are present
2. `cat /sys/power/mem_sleep` — confirm `[s2idle]` is active
3. Let screen sleep via inactivity → move mouse → screen should come back
4. `sudo systemctl suspend` → wake with power button

## Notes

Attempt 1 did not help — screen remained black after suspend.
