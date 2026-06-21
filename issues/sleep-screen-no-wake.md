# After sleep on inactivity, screen does not wake up

**Status:** Backlog

## Notes

- `s2idle` suspend mode is configured (`/etc/systemd/sleep.conf.d/mbp14-suspend.conf`)
- NVMe d3cold is disabled at boot (`mbp14-d3cold.service`) for suspend stability
