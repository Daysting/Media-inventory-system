#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ICONSET="$ROOT/macOS/MediaInventory/MediaInventory/Assets.xcassets/AppIcon.appiconset"
MASTER="$ICONSET/icon_512x512@2x.png"
for POINTS in 16 32 128 256 512; do
  for SCALE in 1 2; do
    PIXELS=$((POINTS * SCALE))
    SUFFIX=""
    if [[ "$SCALE" == 2 ]]; then SUFFIX="@2x"; fi
    DEST="$ICONSET/icon_${POINTS}x${POINTS}${SUFFIX}.png"
    if [[ "$DEST" != "$MASTER" ]]; then
      /usr/bin/sips -z "$PIXELS" "$PIXELS" "$MASTER" --out "$DEST" >/dev/null
    fi
  done
done
echo "Generated macOS app icon sizes from the 1024px master."
