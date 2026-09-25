#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
: "${DEVELOPMENT_TEAM:?Set DEVELOPMENT_TEAM to your Apple Developer team ID.}"
BUILD_ROOT="${BUILD_ROOT:-$ROOT/work/AppStore}"
ARCHIVE_PATH="${ARCHIVE_PATH:-$BUILD_ROOT/MediaInventory.xcarchive}"
EXPORT_PATH="${EXPORT_PATH:-$BUILD_ROOT/Export}"
APP="$ARCHIVE_PATH/Products/Applications/Daysting's Home Inventory System.app"
[[ -d "$APP" ]] || { echo 'Run archive_app_store.sh first.' >&2; exit 1; }
# Fail before export for unsigned validation archives.
codesign --verify --deep --strict "$APP"
mkdir -p "$BUILD_ROOT"
OPTIONS="$BUILD_ROOT/ExportOptions.plist"
cp "$ROOT/macOS/distribution/ExportOptions.plist" "$OPTIONS"
/usr/libexec/PlistBuddy -c "Add :teamID string $DEVELOPMENT_TEAM" "$OPTIONS"
xcodebuild -exportArchive -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_PATH" -exportOptionsPlist "$OPTIONS" -allowProvisioningUpdates
echo "Exported locally: $EXPORT_PATH (not uploaded)"
