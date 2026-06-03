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
    ssh-askpass \
    stterm && \
  echo "**** install antigravity ****" && \
  mkdir -p /opt/antigravity && \
  echo '#!/bin/bash\nxterm -e "echo Antigravity 2 Agent Workspace; bash"' > /opt/antigravity/antigravity && \
  chmod +x /opt/antigravity/antigravity && \
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
