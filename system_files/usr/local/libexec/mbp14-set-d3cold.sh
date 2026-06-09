#!/usr/bin/env bash
set -euo pipefail

# Apply only if the NVMe power-state file exists.
NVME_D3COLD_PATH="/sys/bus/pci/devices/0000:01:00.0/d3cold_allowed"

if [[ -e "${NVME_D3COLD_PATH}" ]]; then
  echo 0 > "${NVME_D3COLD_PATH}"
fi
