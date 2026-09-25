#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD="$ROOT/work/tests"
SOURCE="$ROOT/macOS/MediaInventory/MediaInventory"
mkdir -p "$BUILD"
SWIFT_ARGS=()
if [[ "${CODEX_SWIFT_MACRO_WORKAROUND:-0}" == 1 ]]; then
  SWIFT_ARGS+=(-Xfrontend -disable-sandbox)
fi
xcrun swiftc -D DEBUG -module-cache-path "$BUILD/ModuleCache" ${SWIFT_ARGS[@]+"${SWIFT_ARGS[@]}"} \
  "$SOURCE/DatabaseSnapshotSync.swift" "$SOURCE/ICloudDatabaseCoordinator.swift" \
  "$SOURCE/InventoryImage.swift" "$SOURCE/Models.swift" "$SOURCE/APIClient.swift" \
  "$ROOT/tests/main.swift" -o "$BUILD/InventoryTests"
"$BUILD/InventoryTests"
