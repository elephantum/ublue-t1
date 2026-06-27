#!/usr/bin/env bash
set -euo pipefail

: "${IMAGE_NAME:=ublue-t1}"
: "${VERSION:=latest}"

cat > /usr/lib/os-release <<EOF
NAME="${IMAGE_NAME}"
VERSION="${VERSION}"
ID=${IMAGE_NAME}
ID_LIKE="fedora"
VERSION_ID=44
PLATFORM_ID="platform:f44"
PRETTY_NAME="${IMAGE_NAME} (${VERSION})"
ANSI_COLOR="0;38;2;60;110;180"
LOGO=fedora-logo-icon
DEFAULT_HOSTNAME="mbp-t1"
HOME_URL="https://github.com/elephantum/ublue-t1"
BUG_REPORT_URL="https://github.com/elephantum/ublue-t1/issues"
VARIANT="Silverblue"
VARIANT_ID=silverblue
IMAGE_ID="${IMAGE_NAME}"
EOF

# Keep package install minimal and deterministic for local iteration.
dnf5 install -y \
  iwlwifi-dvm-firmware \
  iwlwifi-mvm-firmware \
  usbutils \
  pciutils || true

chmod +x /usr/libexec/mbp14-set-d3cold.sh 2>/dev/null || true
chmod +x /usr/libexec/mbp-ibridge-rebind.sh 2>/dev/null || true

systemctl enable mbp14-d3cold.service 2>/dev/null || true
systemctl enable mbp-ibridge-rebind.service 2>/dev/null || true
