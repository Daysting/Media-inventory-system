#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODE="${1:-run}"
case "$MODE" in run|--verify|--debug|--logs|--telemetry) ;; *) echo "Usage: $0 [--verify|--debug|--logs|--telemetry]" >&2; exit 2 ;; esac
APP_NAME="Daysting's Home Inventory System"
DERIVED="$ROOT/work/Run"
SIGNING=(CODE_SIGN_IDENTITY=- CODE_SIGN_STYLE=Manual CODE_SIGN_ENTITLEMENTS=MediaInventory.local.entitlements)
if [[ -n "${DEVELOPMENT_TEAM:-}" ]]; then
  SIGNING=("DEVELOPMENT_TEAM=$DEVELOPMENT_TEAM" CODE_SIGN_STYLE=Automatic -allowProvisioningUpdates)
fi
EXTRA=()
if [[ "${CODEX_SWIFT_MACRO_WORKAROUND:-0}" == 1 ]]; then
  EXTRA+=('OTHER_SWIFT_FLAGS=$(inherited) -Xfrontend -disable-sandbox')
fi
pkill -x "$APP_NAME" >/dev/null 2>&1 || true
xcodebuild -project "$ROOT/macOS/MediaInventory/MediaInventory.xcodeproj" \
  -scheme MediaInventory -configuration Debug -destination 'platform=macOS' \
  -derivedDataPath "$DERIVED" "${SIGNING[@]}" ${EXTRA[@]+"${EXTRA[@]}"} build
APP="$DERIVED/Build/Products/Debug/$APP_NAME.app"
if [[ "$MODE" == --debug ]]; then exec lldb -- "$APP/Contents/MacOS/$APP_NAME"; fi
open -n "$APP"
case "$MODE" in
  --verify) sleep 2; pgrep -x "$APP_NAME" >/dev/null ;;
  --logs) exec log stream --info --style compact --predicate "process == \"$APP_NAME\"" ;;
  --telemetry) exec log stream --info --style compact --predicate 'subsystem == "com.erickhofer.MediaInventory"' ;;
esac
