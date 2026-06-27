# Touch ID does not work

**Status:** Backlog

## Research findings

Touch ID on MacBook Pro 2017 (MacBookPro14,3) is routed through the **Apple T1 security coprocessor**. The T1 chip handles biometric authentication via a secure enclave and never exposes the raw fingerprint data over a standard interface.

**Current Linux status: not working, no known workaround.**

Key findings from investigation:

- The [mbp-2016-linux compatibility tracker](https://github.com/Dunedan/mbp-2016-linux) explicitly lists Touch ID as "not working" for all MacBookPro14,x models — no active development noted.
- **libfprint / fprintd** (the standard Linux fingerprint stack) does not list any Apple device in its supported hardware list. Apple Touch ID has never been upstreamed.
- The **apple-ib-drv** project (which we already use for the Touch Bar) only covers the Touch Bar display and the ambient light sensor — it does not touch the fingerprint reader.
- For T2 Macs (2018+), the t2linux wiki lists the T2 Secure Enclave as "not working" for the same fundamental reason: the enclave is a closed security boundary.
- Zero kernel patches submitted to linux-usb or elsewhere for Apple Touch ID support.
- No public reverse-engineering effort has produced a working driver.

**Why it's hard:** The T1 chip deliberately prevents raw fingerprint templates from leaving the secure enclave. Even on macOS, only a yes/no authentication result crosses the boundary. A Linux driver would need to replicate the full SEP authentication protocol, which Apple has not documented.

**Possible future path:** If libfprint ever gains a plugin for the Apple T1/T2 secure enclave protocol (e.g. via reverse engineering similar to what was done for some Synaptics devices), it could be enabled here. No such project currently exists.

## Fixes applied

None — currently not feasible.

## Testing

N/A

## Notes
