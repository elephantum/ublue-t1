ARG BASE_IMAGE=ghcr.io/ublue-os/bluefin-dx:latest
ARG MBP_TOUCHBAR_DKMS_REPO=https://github.com/nanachi2002/macbook12-spi-driver.git
ARG MBP_TOUCHBAR_DKMS_BRANCH=fix/kernel-6.17-compat
ARG MBP_AUDIO_DKMS_REPO=https://github.com/davidjo/snd_hda_macbookpro.git
ARG MBP_AUDIO_DKMS_BRANCH=master
ARG MBP_FAN_DAEMON_REPO=https://github.com/linux-on-mac/mbpfan.git
ARG MBP_FAN_DAEMON_BRANCH=master

# Stage 1a: Build touchbar kernel module using the same base image (guaranteed kernel match)
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

# Stage 1b: Build audio kernel module
FROM ${BASE_IMAGE} AS audio-builder

# Layer 1: Install build deps — cached until base image kernel changes
RUN kernel_version="$(ls /lib/modules/ | sort -V | tail -n1)" && \
    dnf5 install -y dkms git gcc make "kernel-devel-${kernel_version}"

# Layer 2: Clone source — cached until REPO/BRANCH args change
ARG MBP_AUDIO_DKMS_REPO
ARG MBP_AUDIO_DKMS_BRANCH
RUN git clone --depth 1 --branch "${MBP_AUDIO_DKMS_BRANCH}" \
      "${MBP_AUDIO_DKMS_REPO}" /usr/src/audio-driver-src

# Layer 3: DKMS build — cached until script or source changes
COPY build_files/mbp-audio-dkms-build.sh /tmp/build-module.sh
RUN bash /tmp/build-module.sh

# Stage 1c: Build mbpfan fan control daemon (plain userspace binary, no DKMS/kernel-devel needed)
FROM ${BASE_IMAGE} AS fan-builder

# Layer 1: Install build deps
RUN dnf5 install -y make gcc git

# Layer 2: Clone source — cached until REPO/BRANCH args change
ARG MBP_FAN_DAEMON_REPO
ARG MBP_FAN_DAEMON_BRANCH
RUN git clone --depth 1 --branch "${MBP_FAN_DAEMON_BRANCH}" \
      "${MBP_FAN_DAEMON_REPO}" /usr/src/fan-daemon-src

# Layer 3: Build — cached until script or source changes
COPY build_files/mbp-fan-daemon-build.sh /tmp/build-fan.sh
RUN bash /tmp/build-fan.sh

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

COPY --from=audio-builder /output/ /tmp/audio-modules/
RUN kernel_version="$(ls /lib/modules/ | sort -V | tail -n1)" && \
    mkdir -p "/usr/lib/modules/${kernel_version}/extra/" && \
    find /tmp/audio-modules/ -maxdepth 1 \( -name "*.ko" -o -name "*.ko.zst" -o -name "*.ko.xz" \) \
      -exec cp {} "/usr/lib/modules/${kernel_version}/extra/" \; && \
    rm -rf /tmp/audio-modules && \
    find "/usr/lib/modules/${kernel_version}/kernel" -name "snd-hda-codec-cs8409.ko*" -delete && \
    depmod -a "${kernel_version}"

COPY --from=fan-builder /output/mbpfan /usr/sbin/mbpfan
RUN chmod +x /usr/sbin/mbpfan

LABEL org.opencontainers.image.title="${IMAGE_NAME}"
LABEL org.opencontainers.image.description="Custom Bluefin derivative for MacBookPro14,3"
LABEL org.opencontainers.image.vendor="local"
LABEL org.opencontainers.image.version="${VERSION}"
