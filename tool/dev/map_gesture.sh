#!/usr/bin/env bash
# The map gesture check (docs/map/PERFORMANCE.md): runs the long pinch flows
# (map_pinch_sweep, map_pinch_wave) in profile mode, records the phone's
# screen during each, and reports per run Flutter's frame numbers, the map's
# own counts (MapStats) and what the recording shows (gaps, frozen map, frames
# with neither heat nor markers).
#
#   tool/dev/map_gesture.sh <label> [runs]     # e.g. baseline 3
#   MAP_GOOGLE=1 tool/dev/map_gesture.sh google 3   # the Google map instead
#   MAP_FLOWS=map_tap_zoom tool/dev/map_gesture.sh taps 1   # only these flows
#
# Output in build/perf/<label>/run_<n>/: drive.log, perf_numbers.json (the
# MapStats counts as map_pinch_*_<count>), <flow>.timeline_summary.json and
# <flow>.mp4 with <flow>.report.json from tool/dev/map_gesture_report.py.
# Needs build/dev/pyenv (python -m venv; pip install imageio-ffmpeg numpy).
source "$(dirname "$0")/env.sh"

label=${1:?usage: map_gesture.sh <label> [runs]}
runs=${2:-1}
# MAP_FLOWS="map_tap_zoom" runs only those.
read -r -a flows <<<"${MAP_FLOWS:-map_pinch_sweep map_pinch_wave map_tap_zoom}"
# In the order the test plays them (its list of map flows), so each
# recording gets its flow's name.
mapfile -t flows < <(for f in "${flows[@]}"; do
  echo "$(grep -n "'$f'," integration_test/perf_test.dart | head -1 | cut -d: -f1) $f"
done | sort -n | cut -d' ' -f2)
out=build/perf/$label
PY=build/dev/pyenv/Scripts/python
# A fresh folder: the watcher would take an earlier run's finished log for
# this one's.
rm -rf "$out"
# Real touches (tool/dev/touch/Pinch.java) on the phone.
jar=build/dev/touch/pinch.jar
if [ ! "$jar" -nt tool/dev/touch/Pinch.java ] || [ ! "$jar" -nt tool/dev/touch/AnimScale.java ]; then
  "$(dirname "$0")/touch/build.sh" || exit 1
fi
adbs push build/dev/touch/pinch.jar /data/local/tmp/pinch.jar >/dev/null
# Android's animator scale drives MapLibre's tap zooms and zoom coast: at 0
# (it can read "unset" while 0, see AnimScale.java) they jump.
scale=$(adbs shell CLASSPATH=/data/local/tmp/pinch.jar app_process /system/bin AnimScale |
  tr -d '\r' | sed -n 's/^currentAnimatorScale=//p')
if [ "$scale" != "1.0" ]; then
  echo "The phone's animator scale is ${scale:-unknown}, not 1.0: restore it with"
  echo "  adb shell settings put global animator_duration_scale 1.0"
  exit 1
fi
# The phone reaches the emulators through adb reverse, which a USB reconnect
# drops.
for port in 9099 8080 9199 5001; do adbs reverse tcp:$port tcp:$port >/dev/null; done
[ -x "$PY" ] || PY=build/dev/pyenv/bin/python

# Starts and stops a recording at the test's MAPFLOW_START / MAPFLOW_END and
# plays its MAPFINGERS. Read from the phone's own log as it happens (flutter
# drive writes drive.log late, in blocks).
watch_run() {
  local n=$1 log=$out/run_$1/phone.log drive=$out/run_$1/drive.log
  local k=0 ended=0 fingered=0
  until [ -f "$drive" ]; do sleep 0.5; done
  adbs logcat -c
  (adbs logcat -v brief -s flutter:I >"$log" 2>/dev/null &)
  while true; do
    local starts ends
    starts=$(grep -c "MAPFLOW_START" "$log" 2>/dev/null)
    ends=$(grep -c "MAPFLOW_END" "$log" 2>/dev/null)
    if [ "$starts" -gt "$k" ]; then
      k=$starts
      adbs shell rm -f "/sdcard/map_flow_$k.mp4"
      (adbs shell screenrecord --size 540x1200 --bit-rate 12000000 \
        --time-limit 120 "/sdcard/map_flow_$k.mp4" >/dev/null 2>&1 &)
    fi
    # The test asks for real touches (MAPFINGERS cx cy ms gestures...).
    local asked
    asked=$(grep -c "MAPFINGERS" "$log" 2>/dev/null)
    if [ "$asked" -gt "$fingered" ]; then
      fingered=$asked
      local line
      line=$(grep "MAPFINGERS" "$log" | sed -n "${asked}p" | sed 's/.*MAPFINGERS //' | tr -d '\r')
      # shellcheck disable=SC2086
      adbs shell CLASSPATH=/data/local/tmp/pinch.jar app_process /system/bin Pinch $line >/dev/null 2>&1
    fi
    if [ "$ends" -gt "$ended" ]; then
      ended=$ends
      adbs shell pkill -2 screenrecord >/dev/null 2>&1
    fi
    if grep -q "All tests passed\|Some tests failed\|Test failed\|run $n failed" "$log" "$drive"; then
      adbs shell pkill -2 screenrecord >/dev/null 2>&1
      pkill -f "logcat -v brief -s flutter" 2>/dev/null
      sleep 2
      local i=1
      for flow in "${flows[@]}"; do
        if [ $i -le "$k" ]; then
          adbs pull "/sdcard/map_flow_$i.mp4" "$out/run_$n/$flow.mp4" >/dev/null 2>&1
        fi
        i=$((i + 1))
      done
      return
    fi
    sleep 0.3
  done
}

(
  for n in $(seq "$runs"); do watch_run "$n"; done
) &
watcher=$!

MAP_HARNESS=1 FLOWS=$(IFS=,; echo "${flows[*]}") \
  "$(dirname "$0")/perf.sh" "$label" "$runs"
status=$?
wait "$watcher"

for n in $(seq "$runs"); do
  for flow in "${flows[@]}"; do
    video=$out/run_$n/$flow.mp4
    [ -f "$video" ] || continue
    "$PY" -I tool/dev/map_gesture_report.py "$video" >"${video%.mp4}.report.json"
    "$PY" -I tool/dev/map_flash_video.py "$video" >"${video%.mp4}.flash.json"
  done
done
dart run tool/dev/map_gesture_summary.dart "$out"
exit $status
