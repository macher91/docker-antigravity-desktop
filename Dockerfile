# syntax=docker/dockerfile:1

FROM ghcr.io/linuxserver/baseimage-selkies:debiantrixie

# set version label
ARG BUILD_DATE
ARG VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="macher91"

# title
ENV TITLE="Google Antigravity 2" \
    NO_GAMEPAD=true \
    PIXELFLUX_WAYLAND=true

RUN \
  echo "**** add icon ****" && \
  curl -o \
    /usr/share/selkies/www/icon.png \
    https://raw.githubusercontent.com/linuxserver/docker-templates/master/linuxserver.io/img/linuxserver-logo.png && \
  echo "**** install packages ****" && \
  apt-get update && \
  apt-get install --no-install-recommends -y \
    caja \
    chromium \
    chromium-l10n \
    git \
    gnome-keyring \
    libgtk-3-0 \
    squashfs-tools \
    ssh-askpass \
    stterm && \
  echo "**** detect latest antigravity version ****" && \
  GCS_URL="https://storage.googleapis.com/antigravity-public/" && \
  LATEST_VERSION=$(curl -sf "$GCS_URL" | \
    grep -oP 'antigravity-hub/\K[0-9]+\.[0-9]+\.[0-9]+-[0-9]+(?=/linux-x64/)' | \
    sort -t. -k1,1n -k2,2n -k3,3n | \
    tail -1) && \
  echo "==> Latest version: $LATEST_VERSION" && \
  # Check if AppImage exists for this version
  APPIMAGE_URL="https://storage.googleapis.com/antigravity-public/antigravity-hub/${LATEST_VERSION}/linux-x64/Antigravity.AppImage" && \
  TARGZ_URL="https://storage.googleapis.com/antigravity-public/antigravity-hub/${LATEST_VERSION}/linux-x64/Antigravity.tar.gz" && \
  if curl -sfI "$APPIMAGE_URL" > /dev/null 2>&1; then \
    echo "==> Downloading AppImage: $APPIMAGE_URL" && \
    mkdir -p /opt/antigravity && \
    curl -L -o /tmp/Antigravity.AppImage "$APPIMAGE_URL" && \
    chmod +x /tmp/Antigravity.AppImage && \
    cd /tmp && \
    unsquashfs -f -d /opt/antigravity /tmp/Antigravity.AppImage && \
    # AppImage squashfs-root may have a single top-level dir; flatten if needed
    if [ -d /opt/antigravity/squashfs-root ]; then \
      mv /opt/antigravity/squashfs-root/* /opt/antigravity/ && \
      rmdir /opt/antigravity/squashfs-root; \
    fi && \
    rm /tmp/Antigravity.AppImage; \
  else \
    echo "==> Downloading tar.gz: $TARGZ_URL" && \
    mkdir -p /opt/antigravity && \
    curl -L -o /tmp/Antigravity.tar.gz "$TARGZ_URL" && \
    tar xzf /tmp/Antigravity.tar.gz -C /opt/antigravity --strip-components=1 && \
    rm /tmp/Antigravity.tar.gz; \
  fi && \
  chmod +x /opt/antigravity/antigravity && \
  chmod 4755 /opt/antigravity/chrome-sandbox && \
  echo "**** container tweaks ****" && \
  mv \
    /usr/bin/chromium \
    /usr/bin/chromium-real && \
  printf "Linuxserver.io version: ${VERSION}\nBuild-date: ${BUILD_DATE}" > /build_version && \
  echo "**** cleanup ****" && \
  apt-get autoclean && \
  rm -rf \
    /var/lib/apt/lists/* \
    /var/tmp/* \
    /tmp/*

# add local files (openbox menu, chromium/antigravity launchers)
COPY /root /

# ports and volumes
EXPOSE 3001

VOLUME /config
