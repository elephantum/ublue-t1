# After sleep on inactivity, screen does not wake up

**Status:** In Progress

## Root cause

MBP14,3 (15") has Intel iGPU (00:02.0) + AMD dGPU (01:00.0, drives eDP-1).

Two separate problems have been identified:

**Problem A — s2idle causes spurious wakes**: When using s2idle, a device (likely AMD GPU
or USB) generates continuous wake interrupts. The machine loops: sleep → immediate spurious
wake → sleep → ... CPU runs warm, screen never comes back, user must hard-reboot. Confirmed
by journal: s2idle entry logged but no resume; machine heats up.

**Problem B — deep (S3) gives black screen on wake**: The AMD dGPU fails to reinitialize
its display output after S3 resume. Per Dunedan's mbp-2016-linux guide:
"The 15" models with AMD GPU only resume reliably when using the integrated Intel graphics."

## Fixes applied

### Attempt 1 — s2idle + connector detect (failed: spurious wakes)
- `MemorySleepMode=s2idle` in sleep.conf.d
- `mem_sleep_default=s2idle` karg
- Post-resume hook: `echo detect` to eDP connector + backlight restore

### Attempt 2 — s2idle + amdgpu.runpm=0 + VT bounce (failed: spurious wakes + heavier)
- Added `amdgpu.runpm=0` karg
- Updated hook: VT bounce + `pkill -USR2 gnome-shell`
- s2idle still triggered spurious wake loop; machine heated up in both attempts 1 and 2

### Attempt 3 — deep (S3) + display recovery hooks
Reverted to deep sleep which actually suspends properly. Kept `amdgpu.runpm=0` (keeps GPU
powered at full during S3 wake, may help display reinit) and the display recovery hook
(VT bounce + gnome-shell USR2 + backlight restore).

- `MemorySleepMode=deep` in sleep.conf.d
- kargs: `amdgpu.runpm=0` only (no s2idle karg)
- Display hook unchanged: connector detect → VT bounce → gnome-shell USR2 → backlight

## Testing

After rebasing:
1. `cat /sys/power/mem_sleep` — confirm `s2idle [deep]` (deep active)
2. `cat /proc/cmdline` — confirm `amdgpu.runpm=0` present
3. Suspend: `sudo systemctl suspend` → wake with power button — does display come back?
4. Check heating: machine should be cool while suspended

## Notes

Attempts 1 and 2 (s2idle) both caused the machine to heat up during "sleep" —
spurious wake loop, not a real suspend. Had to hard-reboot to recover screen.
