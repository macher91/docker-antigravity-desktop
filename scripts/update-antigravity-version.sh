#!/usr/bin/env bash
# update-antigravity-version.sh
# Sprawdza najnowszą wersję Antigravity dostępną w GCS bucket.
# Dockerfile automatycznie pobiera najnowszą wersję podczas builda,
# więc ten skrypt służy głównie do diagnostyki i monitoringu.
#
# Użycie:
#   ./update-antigravity-version.sh          # sprawdź najnowszą wersję
#   ./update-antigravity-version.sh --check  # sprawdź czy jest nowsza niż obecna w Dockerfile

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
DOCKERFILE="$REPO_DIR/Dockerfile"
GCS_URL="https://storage.googleapis.com/antigravity-public/"

echo "==> Pobieram listę wersji z GCS..."

# Pobierz XML i wyciągnij wszystkie wersje linux-x64
LATEST_VERSION=$(curl -sf "$GCS_URL" | \
  grep -oP 'antigravity-hub/\K[0-9]+\.[0-9]+\.[0-9]+-[0-9]+(?=/linux-x64/)' | \
  sort -t. -k1,1n -k2,2n -k3,3n | \
  tail -1)

if [ -z "$LATEST_VERSION" ]; then
  echo "ERROR: Nie znaleziono żadnej wersji Antigravity" >&2
  exit 1
fi

echo "==> Najnowsza wersja: $LATEST_VERSION"

# Sprawdź format (AppImage vs tar.gz)
APPIMAGE_URL="https://storage.googleapis.com/antigravity-public/antigravity-hub/${LATEST_VERSION}/linux-x64/Antigravity.AppImage"
TARGZ_URL="https://storage.googleapis.com/antigravity-public/antigravity-hub/${LATEST_VERSION}/linux-x64/Antigravity.tar.gz"

if curl -sfI "$APPIMAGE_URL" > /dev/null 2>&1; then
  echo "==> Format: AppImage"
  echo "==> URL: $APPIMAGE_URL"
elif curl -sfI "$TARGZ_URL" > /dev/null 2>&1; then
  echo "==> Format: tar.gz"
  echo "==> URL: $TARGZ_URL"
else
  echo "ERROR: Nie znaleziono pliku dla wersji $LATEST_VERSION" >&2
  exit 1
fi

# Tryb --check: porównaj z obecną wersją w Dockerfile
if [[ "${1:-}" == "--check" ]]; then
  CURRENT=$(grep -oP 'antigravity-hub/\K[0-9]+\.[0-9]+\.[0-9]+(?=-)' "$DOCKERFILE" | head -1 || true)
  if [ -z "$CURRENT" ]; then
    # Dockerfile używa dynamicznego wykrywania — brak hardcoded wersji
    echo "==> Dockerfile używa dynamicznego wykrywania wersji (brak hardcoded URL)"
    echo "==> BUILD automatycznie pobierze: $LATEST_VERSION"
  elif [ "$CURRENT" = "$(echo $LATEST_VERSION | grep -oP '^[0-9]+\.[0-9]+\.[0-9]+')" ]; then
    echo "==> Jesteś na najnowszej wersji ($CURRENT)"
  else
    echo "==> Dostępna nowa wersja: $CURRENT -> $LATEST_VERSION"
    exit 2
  fi
fi
