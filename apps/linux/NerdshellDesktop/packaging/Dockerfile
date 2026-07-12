ARG BASE_IMAGE=ubuntu:22.04
FROM ${BASE_IMAGE}

ARG VERSION=0.1.0
ARG DEB_ARCH=amd64
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential pkg-config libgtk-3-dev libvte-2.91-dev dpkg-dev ca-certificates file \
    && rm -rf /var/lib/apt/lists/*

COPY . /workspace
RUN bash /workspace/apps/linux/NerdshellDesktop/packaging/build-inside-container.sh "$VERSION" "$DEB_ARCH"
