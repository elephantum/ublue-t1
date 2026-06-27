#!/usr/bin/env bash
set -euo pipefail

# Force iBridge re-enumeration so it exposes camera/touchbar interfaces.
# The iBridge starts in a limited mode on Linux boot; deauthorizing and
# re-authorizing the USB device causes it to re-enumerate with full interfaces.
# With missing original EFI assets this is best-effort.
TARGET_ID="1-3"
DEVICE_PATH="/sys/bus/usb/devices/${TARGET_ID}"

if [[ ! -e "${DEVICE_PATH}" ]]; then
  echo "iBridge USB device not found at ${DEVICE_PATH}, skipping"
  exit 0
fi

echo 0 > "${DEVICE_PATH}/authorized"
sleep 2
echo 1 > "${DEVICE_PATH}/authorized"

# After re-enumeration, hid-sensor-hub claims the iBridge sensor/display HID
# interface (USB 1-3:1.3). The apple_ib_tb touchbar driver needs both the
# keyboard/mode interface AND this display interface to activate; with
# hid-sensor-hub holding it, disp_info.hdev stays null and the touchbar
# stays black. Rebind all iBridge HID devices held by hid-sensor-hub to
# apple-ibridge-hid so apple_ib_tb can find both interfaces.
sleep 2
for dev in /sys/bus/hid/devices/0003:05AC:8600.*; do
  [[ -e "${dev}/driver" ]] || continue
  driver=$(basename "$(readlink -f "${dev}/driver")")
  if [[ "${driver}" == "hid-sensor-hub" ]]; then
    devname=$(basename "${dev}")
    echo "Rebinding ${devname} from hid-sensor-hub to apple-ibridge-hid"
    echo "${devname}" > /sys/bus/hid/drivers/hid-sensor-hub/unbind 2>/dev/null || true
    echo "${devname}" > /sys/bus/hid/drivers/apple-ibridge-hid/bind 2>/dev/null || true
  fi
done
