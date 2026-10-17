#!/usr/bin/env bash
# Runs the app on the USB phone against the local emulators and keeps
# `flutter run` reading commands from a control file, so hot reload works
# from scripts (tool/dev/ctl.sh).
#
#   tool/dev/run.sh            # debug, hot reload
#   tool/dev/run.sh --profile  # profile build (numbers; no hot reload)
#
# Output goes to build/dev/run.log; the script returns once the app is up.
source "$(dirname "$0")/env.sh"

CONTROL=$DEV_DIR/control
LOG=$DEV_DIR/run.log
: >"$CONTROL"
: >"$LOG"
if [ -f "$DEV_DIR/run.pid" ] && kill -0 "$(cat "$DEV_DIR/run.pid")" 2>/dev/null; then
  echo "already running (pid $(cat "$DEV_DIR/run.pid")); tool/dev/ctl.sh q first" >&2
  exit 1
fi

(tail -f "$CONTROL" | flutter run -d "$DEVICE" "${DEFINES[@]}" "$@" >"$LOG" 2>&1) &
echo $! >"$DEV_DIR/run.pid"

# Wait for the first frame (or a failure), at most ten minutes.
for _ in $(seq 600); do
  if grep -q "Flutter run key commands\|To hot reload" "$LOG"; then
    grep -m1 "Dart VM Service\|DevTools debugger" "$LOG"
    echo "running; log: $LOG"
    exit 0
  fi
  if grep -q "Error:\|FAILURE:\|Exception:" "$LOG" && ! kill -0 "$(cat "$DEV_DIR/run.pid")" 2>/dev/null; then
    tail -n 30 "$LOG"
    exit 1
  fi
  sleep 1
done
echo "timed out; see $LOG" >&2
exit 1
