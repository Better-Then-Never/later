#!/usr/bin/env bash
# Sends a key command to the app started by tool/dev/run.sh and prints what
# `flutter run` answered.
#
#   tool/dev/ctl.sh r   # hot reload
#   tool/dev/ctl.sh R   # hot restart
#   tool/dev/ctl.sh q   # quit
source "$(dirname "$0")/env.sh"

CONTROL=$DEV_DIR/control
LOG=$DEV_DIR/run.log
key=${1:-r}
before=$(wc -l <"$LOG")
printf '%s\n' "$key" >>"$CONTROL"

case $key in
  q)
    sleep 2
    pkill -f "tail -f $CONTROL" 2>/dev/null
    rm -f "$DEV_DIR/run.pid"
    ;;
  r | R)
    for _ in $(seq 120); do
      if tail -n +"$((before + 1))" "$LOG" | grep -q "Reloaded\|Restarted\|Error\|error:"; then
        break
      fi
      sleep 0.5
    done
    ;;
  *) sleep 1 ;;
esac
tail -n +"$((before + 1))" "$LOG"
