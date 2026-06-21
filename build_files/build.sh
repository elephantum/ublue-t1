#!/usr/bin/env bash
set -euo pipefail

# Feature flags; set to 0 at build time to disable specific layers.
: "${ENABLE_MBP_WIFI:=1}"
: "${ENABLE_MBP_CAMERA:=1}"
: "${ENABLE_MBP_SUSPEND_QUIRK:=1}"
: "${ENABLE_MBP_TOUCHBAR_REBIND:=1}"

# Keep package install minimal and deterministic for local iteration.
dnf5 install -y \
  iwlwifi-dvm-firmware \
  iwlwifi-mvm-firmware \
  usbutils \
  pciutils || true

if [[ "${ENABLE_MBP_WIFI}" != "1" ]]; then
  rm -f /usr/lib/firmware/brcm/brcmfmac43602-pcie.txt || true
  rm -f /etc/modprobe.d/mbp14-brcmfmac.conf || true
  rm -f /etc/modules-load.d/mbp14-brcmfmac.conf || true
fi

if [[ "${ENABLE_MBP_CAMERA}" != "1" ]]; then
  rm -f /etc/modprobe.d/uvcvideo-mbp14.conf || true
fi

if [[ "${ENABLE_MBP_SUSPEND_QUIRK}" != "1" ]]; then
  rm -f /etc/systemd/system/mbp14-d3cold.service || true
  rm -f /usr/libexec/mbp14-set-d3cold.sh || true
  rm -f /etc/systemd/sleep.conf.d/mbp14-suspend.conf || true
  rm -f /usr/lib/bootc/kargs.d/mbp14-sleep.toml || true
  rm -f /usr/lib/systemd/system-sleep/mbp14-display-reset || true
fi

if [[ "${ENABLE_MBP_TOUCHBAR_REBIND}" != "1" ]]; then
  rm -f /etc/systemd/system/mbp-ibridge-rebind.service || true
  rm -f /usr/libexec/mbp-ibridge-rebind.sh || true
fi

chmod +x /usr/libexec/mbp14-set-d3cold.sh 2>/dev/null || true
chmod +x /usr/libexec/mbp-ibridge-rebind.sh 2>/dev/null || true
chmod +x /usr/lib/systemd/system-sleep/mbp14-display-reset 2>/dev/null || true

systemctl enable mbp14-d3cold.service 2>/dev/null || true
systemctl enable mbp-ibridge-rebind.service 2>/dev/null || true
