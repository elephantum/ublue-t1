ARG BASE_IMAGE=ghcr.io/ublue-os/bluefin-dx:latest
ARG MBP_TOUCHBAR_DKMS_REPO=https://github.com/nanachi2002/macbook12-spi-driver.git
ARG MBP_TOUCHBAR_DKMS_BRANCH=fix/kernel-6.17-compat

# Stage 1: Build touchbar kernel module using the same base image (guaranteed kernel match)
FROM ${BASE_IMAGE} AS touchbar-builder

# Layer 1: Install build deps — cached until base image kernel changes
RUN kernel_version="$(ls /lib/modules/ | sort -V | tail -n1)" && \
    dnf5 install -y dkms git gcc make "kernel-devel-${kernel_version}"

# Layer 2: Clone source — cached until REPO/BRANCH args change
ARG MBP_TOUCHBAR_DKMS_REPO
ARG MBP_TOUCHBAR_DKMS_BRANCH
RUN git clone --depth 1 --branch "${MBP_TOUCHBAR_DKMS_BRANCH}" \
      "${MBP_TOUCHBAR_DKMS_REPO}" /usr/src/touchbar-driver-src

# Layer 3: DKMS build — cached until script or source changes
COPY build_files/mbp-touchbar-dkms-build.sh /tmp/build-module.sh
RUN bash /tmp/build-module.sh

# Stage 2: Main image
FROM ${BASE_IMAGE}
ARG IMAGE_NAME=ublue-t1
ARG VERSION=latest

COPY build_files/build.sh /tmp/build.sh
COPY system_files/ /

RUN chmod +x /tmp/build.sh \
    && IMAGE_NAME="${IMAGE_NAME}" VERSION="${VERSION}" /tmp/build.sh \
    && rm -f /tmp/build.sh

COPY --from=touchbar-builder /output/ /tmp/touchbar-modules/
RUN kernel_version="$(ls /lib/modules/ | sort -V | tail -n1)" && \
    mkdir -p "/usr/lib/modules/${kernel_version}/extra/" && \
    find /tmp/touchbar-modules/ -maxdepth 1 \( -name "*.ko" -o -name "*.ko.zst" -o -name "*.ko.xz" \) \
      -exec cp {} "/usr/lib/modules/${kernel_version}/extra/" \; && \
    depmod -a "${kernel_version}" && \
    rm -rf /tmp/touchbar-modules

LABEL org.opencontainers.image.title="${IMAGE_NAME}"
LABEL org.opencontainers.image.description="Custom Bluefin derivative for MacBookPro14,3"
LABEL org.opencontainers.image.vendor="local"
LABEL org.opencontainers.image.version="${VERSION}"
