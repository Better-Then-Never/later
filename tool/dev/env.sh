# Shared settings for the tool/dev scripts (sourced, not run).
#
#   ADB      adb executable (default: adb on PATH, else the Windows SDK path)
#   DEVICE   phone serial (default: the only attached device)
#   EMU_HOST host the app uses for the Firebase emulators (default 127.0.0.1,
#            reached through `adb reverse`, see tool/dev/emulators.sh)

cd "$(dirname "${BASH_SOURCE[0]}")/../.." || exit 1
export MSYS_NO_PATHCONV=1

if [ -z "$ADB" ]; then
  if command -v adb >/dev/null 2>&1; then
    ADB=adb
  elif [ -x /d/AndroidSDK/platform-tools/adb.exe ]; then
    ADB=/d/AndroidSDK/platform-tools/adb.exe
  else
    echo "adb not found; set ADB" >&2
    exit 1
  fi
fi
if [ -z "$DEVICE" ]; then
  DEVICE=$("$ADB" devices | awk 'NR > 1 && $2 == "device" { print $1; exit }')
fi
[ -n "$DEVICE" ] || { echo "no device attached" >&2; exit 1; }
EMU_HOST=${EMU_HOST:-127.0.0.1}
APP_ID=com.btn.later
DEV_DIR=build/dev
mkdir -p "$DEV_DIR"

adbs() { "$ADB" -s "$DEVICE" "$@"; }

DEFINES=(
  --dart-define=USE_FIREBASE_EMULATOR=true
  --dart-define=FIREBASE_EMULATOR_HOST="$EMU_HOST"
)
