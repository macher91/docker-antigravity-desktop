# syntax=docker/dockerfile:1

FROM ghcr.io/linuxserver/baseimage-selkies:debiantrixie

# set version label
ARG BUILD_DATE
ARG VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="thelamer"

# title
ENV TITLE="Google Antigravity 2" \
    NO_GAMEPAD=true \
    PIXELFLUX_WAYLAND=true

RUN \
  echo "**** install packages ****" && \
  apt-get update && \
  apt-get install --no-install-recommends -y \
    caja \
    chromium \
    chromium-l10n \
    curl \
    git \
    gnome-keyring \
    libasound2t64 \
    libgbm1 \
    libgtk-3-0 \
    libnss3 \
    ssh-askpass \
    stterm \
    wget && \
  echo "**** install antigravity ****" && \
  mkdir -p /opt/antigravity && \
  echo '#!/bin/bash\nxterm -e "echo Antigravity 2 Agent Workspace; bash"' > /opt/antigravity/antigravity && \
  chmod +x /opt/antigravity/antigravity && \
  echo "**** cleanup ****" && \
  apt-get autoclean && \
  rm -rf \
    /var/lib/apt/lists/* \
    /var/tmp/* \
    /tmp/*

# add local files
COPY /root /

# ports and volumes
EXPOSE 3001

VOLUME /config
