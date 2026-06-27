#!/usr/bin/env bash
set -euo pipefail

src_dir="/usr/src/audio-driver-src"
kernel_version="$(ls /lib/modules/ | sort -V | tail -n1)"
echo "Building audio module for kernel: ${kernel_version}"

module_name="$(sed -n 's/^PACKAGE_NAME="\?\([^" ]*\)"\?$/\1/p' "${src_dir}/dkms.conf" | head -n1)"
module_version="$(sed -n 's/^PACKAGE_VERSION="\?\([^" ]*\)"\?$/\1/p' "${src_dir}/dkms.conf" | head -n1)"
echo "Module: ${module_name} version ${module_version}"

target_src="/usr/src/${module_name}-${module_version}"
rm -rf "${target_src}"
cp -a "${src_dir}" "${target_src}"

# dkms.conf lists BUILT_MODULE_LOCATION as "build/hda" but the module lands in
# "build/hda/codecs/cirrus" when built against kernel 7.x source layout.
sed -i 's|BUILT_MODULE_LOCATION\[0\]="build/hda"|BUILT_MODULE_LOCATION[0]="build/hda/codecs/cirrus"|g' \
  "${target_src}/dkms.conf"

dkms remove -m "${module_name}" -v "${module_version}" --all 2>/dev/null || true
dkms add     -m "${module_name}" -v "${module_version}"

if ! dkms build -m "${module_name}" -v "${module_version}" --kernelversion "${kernel_version}"; then
  echo "=== DKMS build failed — make.log ==="
  cat "/var/lib/dkms/${module_name}/${module_version}/build/make.log" 2>/dev/null || true
  exit 1
fi

touch /tmp/dkms-install-stamp
dkms install -m "${module_name}" -v "${module_version}" --kernelversion "${kernel_version}"

mkdir -p /output
find "/lib/modules/${kernel_version}" -newer /tmp/dkms-install-stamp \
  \( -name "*.ko" -o -name "*.ko.zst" -o -name "*.ko.xz" \) \
  -exec cp {} /output/ \;

echo "Audio DKMS build complete. Modules: $(ls /output/)"
