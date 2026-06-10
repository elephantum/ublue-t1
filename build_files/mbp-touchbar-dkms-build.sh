#!/usr/bin/env bash
set -euo pipefail

: "${ENABLE_MBP_TOUCHBAR_DKMS:=1}"
: "${MBP_TOUCHBAR_DKMS_REPO:=https://github.com/roadrunner2/macbook12-spi-driver.git}"
: "${MBP_TOUCHBAR_DKMS_BRANCH:=touchbar-driver-hid-driver}"

if [[ "${ENABLE_MBP_TOUCHBAR_DKMS}" != "1" ]]; then
  echo "Touch Bar DKMS layer disabled (ENABLE_MBP_TOUCHBAR_DKMS=${ENABLE_MBP_TOUCHBAR_DKMS})."
  exit 0
fi

echo "Starting best-effort Touch Bar DKMS build layer"

dnf5 install -y \
  dkms \
  git \
  gcc \
  make \
  kernel-devel \
  kernel-headers || true

workdir="$(mktemp -d)"
cleanup() {
  rm -rf "${workdir}"
}
trap cleanup EXIT

src_dir="${workdir}/src"
echo "Using pinned Touch Bar DKMS source: ${MBP_TOUCHBAR_DKMS_REPO} (branch: ${MBP_TOUCHBAR_DKMS_BRANCH})"
if ! git clone --depth 1 --branch "${MBP_TOUCHBAR_DKMS_BRANCH}" "${MBP_TOUCHBAR_DKMS_REPO}" "${src_dir}"; then
  echo "Clone failed for pinned Touch Bar repo"
  exit 0
fi

if [[ ! -f "${src_dir}/dkms.conf" ]]; then
  echo "No dkms.conf in pinned repo/branch; skipping DKMS build"
  exit 0
fi

module_name="$(sed -n 's/^PACKAGE_NAME="\?\([^" ]*\)"\?$/\1/p' "${src_dir}/dkms.conf" | head -n1)"
module_version="$(sed -n 's/^PACKAGE_VERSION="\?\([^" ]*\)"\?$/\1/p' "${src_dir}/dkms.conf" | head -n1)"

if [[ -z "${module_name}" || -z "${module_version}" ]]; then
  echo "Could not parse PACKAGE_NAME/PACKAGE_VERSION from dkms.conf"
  exit 0
fi

target_src="/usr/src/${module_name}-${module_version}"
rm -rf "${target_src}"
cp -a "${src_dir}" "${target_src}"

dkms remove -m "${module_name}" -v "${module_version}" --all || true

if dkms add -m "${module_name}" -v "${module_version}" \
  && dkms build -m "${module_name}" -v "${module_version}" \
  && dkms install -m "${module_name}" -v "${module_version}"; then
  echo "Touch Bar DKMS build succeeded"
else
  echo "Touch Bar DKMS build did not succeed for pinned repo/branch"
fi

exit 0