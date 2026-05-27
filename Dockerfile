FROM lscr.io/linuxserver/baseimage-kasmvnc:ubuntu24.04

# Set browser tab title
ENV TITLE="Google Antigravity 2"

# Install system dependencies
# This is where the downloading and unpacking of the actual Google package
# will eventually take place:
#   curl -o /tmp/antigravity.tar.gz https://antigravity.google/download/linux/amd64/...
#
# Below is a placeholder for environment structure building purposes:
RUN \
  echo "** Updating and installing dependencies **" && \
  apt-get update && \
  apt-get install -y --no-install-recommends \
    curl \
    wget \
    git \
    libnss3 \
    libgbm1 \
    libasound2t64 \
    libgtk-3-0 && \
  echo "** Installing Antigravity 2 **" && \
  mkdir -p /opt/antigravity && \
  echo '#!/bin/bash\nxterm -e "echo Antigravity 2 Agent Workspace; bash"' > /opt/antigravity/antigravity && \
  chmod +x /opt/antigravity/antigravity && \
  echo "** Cleaning up **" && \
  apt-get clean && \
  rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/*

# Copy local configuration files (e.g., autostart for Openbox)
COPY /root /

# Standard linuxserver.io image ports (3000 HTTP, 3001 HTTPS)
EXPOSE 3000 3001

# Volume declarations for configuration and code
VOLUME /config /workspace
