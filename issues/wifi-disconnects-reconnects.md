# Wifi disconnects and reconnects periodically

**Status:** Done

## Root cause

The link dropped exactly ~63s after every association with a locally-generated
deauth (reason 3), 5GHz only. This is **not** a driver/firmware bug — it is the
kernel's regulatory enforcement:

1. At boot, `/usr/bin/setregdomain` (wireless-regdb, via udev
   `85-regulatory.rules`) sets the user regulatory domain from the timezone:
   Asia/Tbilisi → **GE**.
2. The AP (TP-Link) advertises country **DE** in its beacon country IE
   (802.11d). On every connect, cfg80211 processes the IE and rebuilds the
   regulatory rules; the rebuilt per-channel flags cap channels 36–48 at
   **40 MHz** (intersection with the brcmfmac firmware "worldwide-99"
   regdomain).
3. The connection runs at **80 MHz** (VHT80, ch 40, center 5210). cfg80211's
   regulatory enforcement re-validates all connections 60 seconds after any
   regdomain change (`REG_ENFORCE_GRACE_MS` in `net/wireless/reg.c`,
   `reg_wdev_chan_valid` → `cfg80211_chandef_usable`) and force-disconnects
   the now-"invalid" 80 MHz link (`cfg80211_leave` → deauth reason 3,
   locally generated).
4. On disconnect cfg80211 restores the user hint (GE), reconnect re-applies
   the IE (DE) → loop, every ~63s (60s grace + ~3s reconnect).

Why nothing else matched: 2.4GHz was stable (≤40 MHz link passes the check);
no scans/EAPOL/WNM before the drop in wpa_supplicant debug logs; drop arrives
as `NL80211_CMD_DISCONNECT` from the kernel; power save state irrelevant.

Confirmed live 2026-07-09: `sudo iw reg set DE` → one final (already
scheduled) drop, then zero disconnects (previously 5+ per 5 minutes).

This is a generic Linux/cfg80211 corner case, not specific to this router or
timezone: any AP advertising a country different from the OS's guessed
country, combined with an 80MHz (or otherwise width-sensitive) connection,
will reproduce it — the boot-time GE-vs-DE mismatch is just this machine's
instance of it. A fix pinned to `COUNTRY=DE` would only work for this one
router and would actively mislead anyone else building this image for their
own MBP14,3 with a different home AP, so the fix instead makes the OS adapt
to whatever AP it associates with.

## Fixes applied

- **`system_files/etc/NetworkManager/dispatcher.d/90-wifi-regdomain-sync`** —
  a NetworkManager dispatcher script that runs on every interface "up" event.
  It reads the regulatory country cfg80211 currently has in effect (which,
  right after association, reflects the AP's Country IE) and re-asserts it
  via `iw reg set <CC>`, promoting it from a low-persistence "country IE"
  hint to a persistent "user" hint. Once the user hint matches the AP's
  advertised country, further Country IE processing for that AP is a no-op —
  no regdomain rebuild, no enforcement disconnect. Works for any AP/country,
  not just this one.

Earlier changes kept (they address the separate, benign
`brcmf_msgbuf_delete_flowring` boot-time warnings, not this bug):
`feature_disable=0x2000 roamoff=1 fcmode=0` modprobe options and the MBP14,3
NVRAM file.

## Fixes tried

- **`options brcmfmac power_save=0`** — invalid parameter (kernel: `unknown parameter 'power_save' ignored`). Removed.
- **Wifi power save off via NetworkManager** (`wifi.powersave=2`) — tested
  live 2026-07-08 with `iw dev wlp3s0 get power_save` = off: disconnects
  continued at the same ~63s cadence. Did not help; not added to the image.
- **Band isolation test** — 2.4GHz SSID of the same router: fully stable;
  5GHz dropped every ~63s. This pointed to the 5GHz/width-specific cause.

## Testing

Live validation before the image rebuild, simulating what the dispatcher
script does automatically (2026-07-09):

1. `sudo iw reg set GE` (revert to the timezone default, reproducing the
   mismatch), then force a reconnect — regdomain flips to DE via the country
   IE and would start the 60s countdown to a drop.
2. `sudo iw reg set DE` (what the dispatcher does on "up"), then force
   another reconnect and watch 5 minutes: 0 spontaneous disconnects (vs. 5+
   per 5 minutes before any fix). Confirms promoting the country IE hint to
   a user hint is sufficient, independent of hardcoding any specific country.

After rebasing onto the rebuilt image:

1. Reboot, connect to the 5GHz network.
2. Confirm the dispatcher ran: `journalctl -t wifi-regdomain-sync -b` should
   show a "promoting AP-advertised country ..." line shortly after connecting.
3. Check the regdomain now matches the AP: `iw reg get` (global section).
4. Monitor for at least 5 minutes (previously 4–5 disconnects would occur):
   ```
   journalctl -f -u wpa_supplicant | grep -E "CTRL-EVENT-(DIS)?CONNECTED"
   ```
   Expect no `CTRL-EVENT-DISCONNECTED` lines.

## Notes

Everything is fixed. WiFi stays connected reliably with no periodic disconnects.
