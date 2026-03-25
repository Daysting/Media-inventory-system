#!/usr/bin/env zsh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR/MediaInventory"
PROJECT_FILE="$PROJECT_DIR/MediaInventory.xcodeproj"
SCHEME="MediaInventory"
APP_NAME="Daysting's Home Inventory System"
VERSION="${1:-1.5}"
BUILD_ROOT="$PROJECT_DIR/build/distribution"
DERIVED_DATA="$BUILD_ROOT/DerivedData"
PRODUCTS_DIR="$DERIVED_DATA/Build/Products/Release"
APP_PATH="$PRODUCTS_DIR/$APP_NAME.app"
STAGING_DIR="$BUILD_ROOT/dmg-root"
DMG_PATH="$BUILD_ROOT/MediaInventory-${VERSION}.dmg"

mkdir -p "$BUILD_ROOT"

xcodebuild \
  -project "$PROJECT_FILE" \
  -scheme "$SCHEME" \
  -configuration Release \
  -destination "platform=macOS" \
  -derivedDataPath "$DERIVED_DATA" \
  CODE_SIGNING_ALLOWED=NO \
  clean build

if [[ ! -d "$APP_PATH" ]]; then
  echo "App bundle not found at: $APP_PATH"
  exit 1
fi

rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR"
cp -R "$APP_PATH" "$STAGING_DIR/"
ln -s /Applications "$STAGING_DIR/Applications"

rm -f "$DMG_PATH"
hdiutil create \
  -volname "$APP_NAME $VERSION" \
  -srcfolder "$STAGING_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

echo "DMG created: $DMG_PATH"
