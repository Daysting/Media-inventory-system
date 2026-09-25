#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODE="${1:-signed}"
BUILD_ROOT="${BUILD_ROOT:-$ROOT/work/AppStore}"
ARCHIVE_PATH="${ARCHIVE_PATH:-$BUILD_ROOT/MediaInventory.xcarchive}"
SIGNING=()
case "$MODE" in
  signed)
    : "${DEVELOPMENT_TEAM:?Set DEVELOPMENT_TEAM to your Apple Developer team ID.}"
    SIGNING+=("DEVELOPMENT_TEAM=$DEVELOPMENT_TEAM" CODE_SIGN_STYLE=Automatic -allowProvisioningUpdates)
    ;;
  --unsigned) SIGNING+=(CODE_SIGNING_ALLOWED=NO) ;;
  *) echo "Usage: DEVELOPMENT_TEAM=TEAMID $0 [signed|--unsigned]" >&2; exit 2 ;;
esac
mkdir -p "$BUILD_ROOT"
EXTRA=()
if [[ "${CODEX_SWIFT_MACRO_WORKAROUND:-0}" == 1 ]]; then
  EXTRA+=('OTHER_SWIFT_FLAGS=$(inherited) -Xfrontend -disable-sandbox')
fi
if [[ -n "${BUILD_NUMBER:-}" ]]; then EXTRA+=("CURRENT_PROJECT_VERSION=$BUILD_NUMBER"); fi
xcodebuild -project "$ROOT/macOS/MediaInventory/MediaInventory.xcodeproj" \
  -scheme MediaInventory -configuration Release -destination 'generic/platform=macOS' \
  -derivedDataPath "$BUILD_ROOT/DerivedData" -archivePath "$ARCHIVE_PATH" \
  ONLY_ACTIVE_ARCH=NO 'ARCHS=arm64 x86_64' SKIP_INSTALL=NO \
  "${SIGNING[@]}" ${EXTRA[@]+"${EXTRA[@]}"} archive
APP="$ARCHIVE_PATH/Products/Applications/Daysting's Home Inventory System.app"
/usr/bin/plutil -lint "$APP/Contents/Info.plist" "$APP/Contents/Resources/PrivacyInfo.xcprivacy"
ARCHITECTURES="$(/usr/bin/lipo -archs "$APP/Contents/MacOS/Daysting's Home Inventory System")"
for ARCH in arm64 x86_64; do
  case " $ARCHITECTURES " in *" $ARCH "*) ;; *) echo "Missing architecture: $ARCH" >&2; exit 1 ;; esac
done
if [[ "$MODE" == signed ]]; then
  /usr/bin/codesign --verify --deep --strict --verbose=2 "$APP"
else
  echo 'Unsigned validation archive only. This archive cannot be submitted to Apple.'
fi
echo "Archive: $ARCHIVE_PATH"
