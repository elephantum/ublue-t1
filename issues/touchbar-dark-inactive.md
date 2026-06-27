# Touchbar is dark and inactive

**Status:** Done

## Root cause

`hid-sensor-hub` claims the iBridge's sensor/display HID interface (USB
interface 1-3:1.3, HID device `0003:05AC:8600.000A`) before
`apple-ibridge-hid` can. The `apple_ib_tb` driver requires **both** the
keyboard/mode interface (`mode_info.hdev`) and the display interface
(`disp_info.hdev`) to be populated before it activates:

```c
if (tb_dev->mode_info.hdev && tb_dev->disp_info.hdev) {
    appletb_mark_active(tb_dev, true);
    ...
}
```

`mode_info` is found on interface 1-3:1.2 (managed by `apple-ibridge-hid`),
but `disp_info` lives on interface 1-3:1.3 (stolen by `hid-sensor-hub`), so
`disp_info.hdev` stays null and the touchbar is never activated.

## Fixes applied

Extended `system_files/usr/libexec/mbp-ibridge-rebind.sh`: after the USB
re-enumeration, wait for HID devices to settle, then rebind any iBridge HID
device held by `hid-sensor-hub` to `apple-ibridge-hid`. This triggers a
second `appletb_probe()` call that fills `disp_info`, passing the both-interfaces
guard and activating the touchbar (mode=function-keys, display=on).

Side effect: ALS transitions from `hid-sensor-hub`→`hid_sensor_als` to
`apple_ibridge`→`apple_ib_als`. Both are IIO drivers; functionality should
be equivalent.

## Testing

1. Build the image: `just build`
2. Rebase: `just rebase-local && sudo systemctl reboot`
3. After boot, check touchbar lights up with function key labels
4. Verify service ran: `systemctl status mbp-ibridge-rebind.service`
5. Verify both iBridge HID devices are on `apple-ibridge-hid`:
   `ls -l /sys/bus/hid/devices/0003:05AC:8600.*/driver | grep -o '[^/]*$'`
   — both should say `apple-ibridge-hid`
6. Verify touchbar mode is active:
   `cat /sys/module/apple_ib_tb/parameters/fnmode`

## Notes

- DKMS build infrastructure in place (multi-stage Containerfile with `nanachi2002/macbook12-spi-driver` fork, branch `fix/kernel-6.17-compat`)
- iBridge rebind service runs at boot (`mbp-ibridge-rebind.service`)
