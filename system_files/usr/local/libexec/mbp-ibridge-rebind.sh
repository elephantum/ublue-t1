#!/usr/bin/env bash
set -euo pipefail

# With missing original EFI assets, this may or may not restore Touch Bar.
USB_ID_PATH="/sys/bus/usb/drivers/usb"
TARGET_ID="1-3"

if [[ -w "${USB_ID_PATH}/unbind" && -w "${USB_ID_PATH}/bind" ]]; then
  echo "${TARGET_ID}" > "${USB_ID_PATH}/unbind" || true
  echo "${TARGET_ID}" > "${USB_ID_PATH}/bind" || true
fi
