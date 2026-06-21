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
