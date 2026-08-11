#!/usr/bin/env bash
set -euo pipefail

# Installs dkms/build tooling plus the kernel-devel package matching the
# image's running kernel exactly (required for DKMS module builds, and for
# the resulting module to load in the final stage which is built from the
# same pristine base image).
#
# Fedora's `updates` repo only carries the single latest kernel build, and
# `updates-archive` lags behind — there's a window right after a kernel bump
# where the base image's kernel has no matching kernel-devel in any enabled
# repo. In that window, `dnf5 install dkms` silently upgrades the kernel
# itself (dkms has a rich dependency `kernel-devel-matched if kernel-core`,
# and dnf5's solver satisfies it by installing whatever newer kernel *does*
# have a matching kernel-devel) — which would build the module against a
# kernel version the final stage doesn't have. Koji retains every build
# indefinitely, so fetch the exact NVR of both kernel-devel and its
# kernel-devel-matched pointer from there and install them alongside dkms in
# one transaction, so the solver never needs to touch the kernel package.

kernel_version="$(ls /lib/modules/ | sort -V | tail -n1)"

if dnf5 install -y dkms git gcc make "kernel-devel-${kernel_version}"; then
  exit 0
fi

echo "kernel-devel-${kernel_version} not available in enabled repos; fetching matching build from Fedora koji" >&2

koji_version="${kernel_version%%-*}"
koji_release="${kernel_version#*-}"
koji_release="${koji_release%.x86_64}"
koji_base="https://kojipkgs.fedoraproject.org/packages/kernel/${koji_version}/${koji_release}/x86_64"

curl -fsSL -o /tmp/kernel-devel.rpm "${koji_base}/kernel-devel-${kernel_version}.rpm"
curl -fsSL -o /tmp/kernel-devel-matched.rpm "${koji_base}/kernel-devel-matched-${kernel_version}.rpm"
dnf5 install -y /tmp/kernel-devel.rpm /tmp/kernel-devel-matched.rpm dkms git gcc make
rm -f /tmp/kernel-devel.rpm /tmp/kernel-devel-matched.rpm
