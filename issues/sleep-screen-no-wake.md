# Suspend from GNOME menu does not wake up

**Status:** Backlog

## Description

Sleep on inactivity works fine — system wakes on keyboard, screen comes back, all good.

However, when selecting "Suspend" from the GNOME menu, the system does not wake up: screen stays dark and keyboard does not light up (suggesting the whole system may not be waking, not just the display).

## Notes

- `s2idle` suspend mode is configured (`/etc/systemd/sleep.conf.d/mbp14-suspend.conf`)
- NVMe d3cold is disabled at boot (`mbp14-d3cold.service`) for suspend stability
