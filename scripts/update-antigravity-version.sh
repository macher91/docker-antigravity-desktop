#!/usr/bin/env bash
# update-antigravity-version.sh
# Pobiera listę wersji Antigravity z GCS bucket i aktualizuje Dockerfile
# z najnowszą wersją linux-x64 tar.gz.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
DOCKERFILE="$REPO_DIR/Dockerfile"
GCS_URL="https://storage.googleapis.com/antigravity-public/"

echo "==> Pobieram listę wersji z GCS..."

# Pobierz XML listę bucketów i wyciągnij wszystkie wersje antigravity-hub/linux-x64
VERSIONS=$(curl -sf "$GCS_URL" | \
  grep -oP 'antigravity-hub/\K[0-9]+\.[0-9]+\.[0-9]+-[0-9]+(?=/linux-x64/Antigravity\.tar\.gz)' | \
  sort -t. -k1,1n -k2,2n -k3,3n | \
  tail -1)

if [ -z "$VERSIONS" ]; then
  echo "ERROR: Nie znaleziono żadnej wersji Antigravity" >&2
  exit 1
fi

echo "==> Najnowsza wersja: $VERSIONS"

# Zbuduj nowy URL
NEW_URL="https://storage.googleapis.com/antigravity-public/antigravity-hub/${VERSIONS}/linux-x64/Antigravity.tar.gz"

# Sprawdź czy URL jest dostępny
if ! curl -sfI "$NEW_URL" > /dev/null 2>&1; then
  echo "ERROR: URL nie istnieje: $NEW_URL" >&2
  exit 1
fi

echo "==> URL: $NEW_URL"

# Aktualizuj Dockerfile
if grep -q "ANTIGRAVITY_URL=" "$DOCKERFILE"; then
  # Zamień istniejący URL
  sed -i "s|ARG ANTIGRAVITY_URL=.*|ARG ANTIGRAVITY_URL=\"${NEW_URL}\"|" "$DOCKERFILE"
  echo "==> Dockerfile zaktualizowany"
else
  echo "ERROR: Nie znaleziono ARG ANTIGRAVITY_URL w Dockerfile" >&2
  exit 1
fi

# Sprawdź czy jest zmiana
if git -C "$REPO_DIR" diff --quiet; then
  echo "==> Brak zmian - Dockerfile już ma najnowszą wersję"
  exit 0
fi

# Commit i push
git -C "$REPO_DIR" add Dockerfile
git -C "$REPO_DIR" commit -m "chore: update Antigravity to ${VERSIONS}"
git -C "$REPO_DIR" push origin main

echo "==> Zaktualizowano i pushowano Antigravity ${VERSIONS}"
