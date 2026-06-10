ARG BASE_IMAGE=ghcr.io/ublue-os/bluefin:latest
FROM ${BASE_IMAGE}

ARG ENABLE_MBP_TOUCHBAR_DKMS_LAYER=1
ARG MBP_TOUCHBAR_DKMS_REPO=
ARG MBP_TOUCHBAR_DKMS_BRANCH=touchbar-driver-hid-driver
ENV ENABLE_MBP_TOUCHBAR_DKMS=${ENABLE_MBP_TOUCHBAR_DKMS_LAYER}
ENV MBP_TOUCHBAR_DKMS_REPO=${MBP_TOUCHBAR_DKMS_REPO}
ENV MBP_TOUCHBAR_DKMS_BRANCH=${MBP_TOUCHBAR_DKMS_BRANCH}

COPY build_files/build.sh /tmp/build.sh
COPY system_files/ /

RUN chmod +x /tmp/build.sh \
    && /tmp/build.sh \
    && rm -f /tmp/build.sh

# Separate layer: best-effort Touch Bar driver DKMS build.
COPY build_files/mbp-touchbar-dkms-build.sh /tmp/mbp-touchbar-dkms-build.sh
RUN chmod +x /tmp/mbp-touchbar-dkms-build.sh \
    && /tmp/mbp-touchbar-dkms-build.sh \
    && rm -f /tmp/mbp-touchbar-dkms-build.sh

LABEL org.opencontainers.image.title="mbp14-3-bluefin"
LABEL org.opencontainers.image.description="Local Bluefin derivative for MacBookPro14,3"
LABEL org.opencontainers.image.vendor="local"
