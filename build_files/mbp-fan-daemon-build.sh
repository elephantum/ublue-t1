#!/usr/bin/env bash
set -euo pipefail

src_dir="/usr/src/fan-daemon-src"
echo "Building mbpfan daemon"

cd "${src_dir}"
make

mkdir -p /output
cp bin/mbpfan /output/

echo "mbpfan build complete."
