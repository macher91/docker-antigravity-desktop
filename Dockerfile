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

ARG ANTIGRAVITY_URL="https://storage.googleapis.com/antigravity-public/antigravity-hub/2.0.11-5731625217163264/linux-x64/Antigravity.tar.gz"

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
    ssh-askpass \
    stterm && \
  echo "**** install antigravity ****" && \
  mkdir -p /opt/antigravity && \
  curl -L -o /tmp/Antigravity.tar.gz "${ANTIGRAVITY_URL}" && \
  tar xzf /tmp/Antigravity.tar.gz -C /opt/antigravity --strip-components=1 && \
  rm /tmp/Antigravity.tar.gz && \
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
