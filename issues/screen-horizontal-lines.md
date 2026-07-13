# Screen shows horizontal lines after some use

**Status:** Testing

## Root cause

Not yet confirmed. Suspected thermal issue: the MacBook's display cable runs
through the lid hinge ("radiator hinge"), and Linux does not apply Apple's
fan curves the way macOS does — the fans tend to stay quiet and let the
machine run hotter for longer before ramping up. Sustained heat at that
hinge is a known cause of intermittent horizontal line artifacts on Apple
displays of this era.

## Fixes applied

Added the `mbpfan` daemon as a software mitigation to make the fans ramp up
earlier, before heat builds up at the hinge:

- **`build_files/mbp-fan-daemon-build.sh`** + a new `fan-builder` stage in
  the `Containerfile` — clones and compiles `mbpfan` (plain userspace C
  binary, no DKMS/kernel-devel needed) from
  `https://github.com/linux-on-mac/mbpfan.git` (the actively maintained
  fork; the original `tburette/mbpfan` package was dropped from Fedora 44).
  The binary is copied to `/usr/sbin/mbpfan` in the final image.
- **`system_files/etc/mbpfan.conf`** — tuned thresholds: `low_temp=60`,
  `high_temp=65` (fans ramp up in this range, per the proposed fix),
  `max_temp=86` (unchanged from upstream default, full speed above this).
- **`system_files/etc/systemd/system/mbpfan.service`** — runs `mbpfan -f`,
  `Restart=always`, enabled via `multi-user.target`.
- **`system_files/etc/modules-load.d/mbp14-fan.conf`** — explicitly loads
  `coretemp` and `applesmc` at boot (belt-and-suspenders; these are usually
  auto-loaded on real Mac hardware via DMI/ACPI match, matching the pattern
  already used for `brcmfmac`/audio in this repo).
- `build_files/build.sh` now enables `mbpfan.service`.
- Build args `MBP_FAN_DAEMON_REPO`/`MBP_FAN_DAEMON_BRANCH` (README + Justfile)
  let this be overridden/forked like the touchbar and audio drivers.

Verified locally (no sudo/hardware access in the dev environment) that the
`mbpfan` source compiles cleanly with plain `make` and that the `-f`
(foreground) flag used in the systemd unit exists. The full container image
build and on-hardware behavior still need to be verified by the user.

## Testing

1. `just build` then `just rebase-local`, reboot.
2. Confirm the daemon is running: `systemctl status mbpfan` should show
   `active (running)`.
3. Confirm `coretemp`/`applesmc` are loaded: `lsmod | grep -e coretemp -e applesmc`.
4. Watch fan behavior under load: run something CPU-heavy (e.g. a build) and
   watch `sensors` (package temp) alongside fan RPM
   (`cat /sys/devices/platform/applesmc.768/fan1_output`, or `sensors` if it
   shows fan speed) — fans should start ramping up around 60°C instead of
   waiting for the stock Linux curve.
5. Use the laptop under sustained load (video playback, compiling, etc.) for
   an extended period and watch for horizontal line artifacts recurring. This
   is the real confirmation and will take longer than a single session to be
   confident about.

## Notes
