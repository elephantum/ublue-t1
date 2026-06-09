ARG BASE_IMAGE=ghcr.io/ublue-os/bluefin:latest
FROM ${BASE_IMAGE}

COPY build_files/build.sh /tmp/build.sh
COPY system_files/ /

RUN chmod +x /tmp/build.sh \
    && /tmp/build.sh \
    && rm -f /tmp/build.sh

LABEL org.opencontainers.image.title="mbp14-3-bluefin"
LABEL org.opencontainers.image.description="Local Bluefin derivative for MacBookPro14,3"
LABEL org.opencontainers.image.vendor="local"
