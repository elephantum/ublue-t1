# Add ability to hibernate

**Status:** Done

## Conclusion

Hibernation does not work on this hardware. Every software-side prerequisite
was correctly configured (see Investigation below), yet the kernel silently
refuses to advertise hibernate support at all. This looks like a
firmware/ACPI limitation specific to this Mac generation, not something
fixable from the OS config side — the same category of dead end as
[Touch ID](touch-id-not-working.md).

Independent evidence from the wider Linux-on-Mac community points the same
way: [Dunedan/mbp-2016-linux](https://github.com/Dunedan/mbp-2016-linux)
(the same compatibility tracker cited in the Touch ID issue) doesn't
document hibernation as working for any 2016/2017 MacBook Pro model, and
first-hand reports from users on this same hardware generation — including
MacBookPro14,3 specifically — describe `systemctl hibernate` effectively
just shutting the machine down instead of hibernating, or not working at
all. No one has published a working fix.

## Background

[Suspend from GNOME menu does not wake up](sleep-screen-no-wake.md) ended in
disabling suspend-to-RAM entirely: S2idle resume on this hardware reliably
leaves PCIe root ports, both Thunderbolt controllers and both xHCI
controllers wedged, and sometimes hangs the machine outright. Hibernate
looked promising as an alternative because resuming from hibernate is a
full cold boot (real BIOS/UEFI POST) rather than a warm PCIe/USB/Thunderbolt
resume — exactly the kind of recovery path that reliably works after a hard
power-off per that issue's notes. In practice this didn't matter: hibernate
itself never becomes available at the kernel level on this hardware, so it
never got far enough to test whether that theory held up.

## Investigation

Hibernation on an ostree/bootc image needs three host-specific pieces that
can't be baked statically into the container image: a real swapfile (the
machine only has zram, which can't back hibernation), a resume offset
(btrfs is copy-on-write, so a swapfile's physical layout is only known once
it exists on the target disk — `btrfs filesystem mkswapfile` /
`btrfs inspect-internal map-swapfile -r` handle this), and
`resume=`/`resume_offset=` kernel args (set via `rpm-ostree kargs`, take
effect on the next boot). All of this was built as a boot-time systemd
service and tested for real on a PR-tagged image:

- An early version of the fix also manually regenerated the image's
  baked-in initramfs (`dracut --force --no-hostonly ...`) to force-include
  dracut's `resume` module. **That broke boot entirely** — the machine
  failed early in initramfs with no persisted log trace (failure happened
  before `/var` was mounted). Root-caused (via process of elimination) to
  that manual dracut regen likely dropping a module the base image's own
  build tooling normally includes (e.g. the `ostree` module needed to
  interpret the `ostree=` kernel parameter). Turned out to be unnecessary
  anyway — `lsinitrd` on the base image's default initramfs confirmed the
  `resume` module is already included without any forced regen.
- With that step removed, the rebuilt PR image booted fine. The setup
  service correctly created an 18G `/var/swap/swapfile`, activated it, and
  staged `resume=UUID=...`/`resume_offset=...` via `rpm-ostree kargs`.
- One more reboot later, `/proc/cmdline` had `resume=`/`resume_offset=`
  active, `/sys/power/resume` resolved to the real device (`259:4`,
  `/dev/nvme0n1p4`), and swap was confirmed active in `/proc/swaps`.
- Despite all of that, `/sys/power/state` never listed `disk` (only
  `freeze mem`), and `/sys/power/disk` showed only `[disabled]`.
  `systemctl hibernate` failed cleanly: "Sleep verb 'hibernate' is not
  configured or configuration is not supported by kernel." Writing `disk`
  directly to `/sys/power/state` as root was rejected with **zero** kernel
  log output, even with `pm_debug_messages=1` enabled — not an error during
  an attempt, a silent refusal to advertise the capability at all.
- Every documented cause of that specific silent-refusal pattern was
  individually checked and ruled out: kernel lockdown
  (`/sys/kernel/security/lockdown` = `[none]`), Secure Boot (disabled),
  FIPS mode (`/proc/sys/crypto/fips_enabled` = `0`), IMA/EVM enforcement
  ("No architecture policies found" — not enforcing), `nohibernate` on the
  kernel command line (absent), `CONFIG_HIBERNATION` (`=y`), ACPI S4
  support (DSDT reports `supports S0 S3 S4 S5`).

## Fixes applied

None kept. The swapfile service, dracut.conf.d snippet, and
`AllowHibernation=yes` change were built and tested (see Investigation
above) but reverted once hibernation was confirmed not to work — no point
carrying dead infrastructure. `mbp14-suspend.conf` is back to disabling
`AllowHibernation` along with the other sleep states.

## Testing

N/A — not pursuing further absent a firmware/kernel change upstream that
would make this feasible.

## Notes
