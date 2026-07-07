# Suspend from GNOME menu does not wake up

**Status:** Backlog

## Description

Sleep on inactivity works fine — system wakes on keyboard, screen comes back, all good.

However, when selecting "Suspend" from the GNOME menu, the system does not wake up: screen stays dark and keyboard does not light up (suggesting the whole system may not be waking, not just the display).

## Root cause (investigation, 2026-07-07)

Reviewed `journalctl -b -1` (the boot where this last happened, 2026-07-07 15:50–16:46) and the fresh boot that followed a forced power-off (2026-07-07 21:07). Findings:

- **16:08:09** — system suspended normally (`PM: suspend entry (s2idle)`).
- **16:31:53** — system resumed (`slept 23m43s` per tailscaled) but the resume was badly broken:
  - Multiple PCIe root ports failed to power back up: `Unable to change power state from D0/D3hot/D3cold to D0, device inaccessible` for several `pcieport` devices.
  - Both Thunderbolt controllers and both `xhci_hcd` USB controllers (`0000:07:00.0`, `0000:7d:00.0`) came back "not ready" and eventually gave up after 65+ seconds, triggering kernel WARNs in `tb_cfg_read` and `pci_disable_device`, and both USB host controllers were torn down and re-enumerated (`USB disconnect`, `Host halt failed`, `Host not accessible, reset failed`).
  - `nvme0` hit an I/O timeout during this window.
  - Wifi (`brcmfmac`) failed to leave D3cold (`Unable to change power state from D3cold to D0, device inaccessible`, `probe after resume failed, err=-19`) — same symptom as [Wifi disconnects and reconnects periodically](wifi-disconnects-reconnects.md).
  - Despite all this, the resume eventually completed and the desktop was usable again.
- **16:46:53** — system was suspended again (`PM: suspend entry (s2idle)`). This is the **last line in that boot's journal** — no resume, no error, nothing. The machine was completely unresponsive (screen dark, keyboard unlit) until forced off.
- Confirmed via the next boot: it was a cold boot (full BIOS memory map dump) and `systemd-fsck` reported `Fs was not properly unmounted`, `recovering journal`, `Dirty bit is set` — consistent with a hard power-off, not a clean shutdown.

**Hypothesis:** the first resume left the PCIe/Thunderbolt/USB4 subsystem in a degraded state (root ports and both xHCI controllers had to be torn down and rebuilt). A subsequent suspend attempt on top of that degraded state appears to hang the machine completely during suspend or resume, before any kernel messages can be logged — a harder failure than the "clean" no-wake case this issue was originally opened for.

## Notes

- `s2idle` suspend mode is configured (`/etc/systemd/sleep.conf.d/mbp14-suspend.conf`)
- NVMe d3cold is disabled at boot (`mbp14-d3cold.service`) for suspend stability
- Also reproduces when the lid is closed to put the system to sleep: reopening the lid does not wake it up (screen stays dark, keyboard does not light up), consistent with the GNOME-menu suspend case above
- 2026-07-07: reproduced again, requiring a hard power-off. Preceded by a rocky resume from an earlier suspend (see Root cause above) — worth testing whether avoiding back-to-back suspend/resume cycles, or fixing the wifi D3cold resume failure, reduces how often the full hang happens
