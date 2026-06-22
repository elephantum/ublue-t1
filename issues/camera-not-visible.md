# Camera does not show up in standard apps like "Camera"

**Status:** Done

## Root cause

iBridge (`05ac:1281`) starts in "Recovery Mode" on Linux boot, exposing only DFU/vendor-specific interfaces — no UVC camera interface.

The original rebind script wrote to `/sys/bus/usb/drivers/usb/unbind` (hub driver), which silently does nothing for non-hub devices like the iBridge.

## Fix applied

Changed rebind to use USB device authorization:

```bash
echo 0 > /sys/bus/usb/devices/1-3/authorized
sleep 2
echo 1 > /sys/bus/usb/devices/1-3/authorized
```

This forces USB re-enumeration, which should cause the iBridge to expose its full interface set including the UVC camera.

## Uncertainty

The EFI partition is gone. The T1 chip normally gets initialized by the macOS EFI bootloader. Without it, the iBridge may stay in recovery mode regardless of rebind. This can only be confirmed by testing.

## How to test

After rebase and reboot:

```bash
lsusb              # check if iBridge shows more interfaces than before
ls /dev/video*     # check if camera appears as a video device
```

## Test results

Did not help, will restore EFI and try again

**Resolution:** Restoring the EFI partition fixed the camera. The T1 chip requires macOS EFI initialization to expose the full UVC interface — without it, iBridge stays in recovery mode regardless of USB rebind tricks.
