#!/usr/bin/env bash
# The map gesture check (docs/map/PERFORMANCE.md): runs the long pinch flows
# (map_pinch_sweep, map_pinch_wave) in profile mode, records the phone's
# screen during each, and reports per run Flutter's frame numbers, the map's
# own counts (MapStats) and what the recording shows (gaps, frozen map, frames
# with neither heat nor markers).
#
#   tool/dev/map_gesture.sh <label> [runs]     # e.g. baseline 3
#
# Output in build/perf/<label>/run_<n>/: drive.log, perf_numbers.json (the
# MapStats counts as map_pinch_*_<count>), <flow>.timeline_summary.json and
# <flow>.mp4 with <flow>.report.json from tool/dev/map_gesture_report.py.
# Needs build/dev/pyenv (python -m venv; pip install imageio-ffmpeg numpy).
source "$(dirname "$0")/env.sh"

label=${1:?usage: map_gesture.sh <label> [runs]}
runs=${2:-1}
flows=(map_pinch_sweep map_pinch_wave)
out=build/perf/$label
PY=build/dev/pyenv/Scripts/python
[ -x "$PY" ] || PY=build/dev/pyenv/bin/python

# Starts and stops a recording at the test's MAPFLOW_START / MAPFLOW_END.
watch_run() {
  local n=$1 log=$out/run_$1/drive.log k=0 ended=0
  until [ -f "$log" ]; do sleep 0.5; done
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
    if [ "$ends" -gt "$ended" ]; then
      ended=$ends
      adbs shell pkill -2 screenrecord >/dev/null 2>&1
    fi
    if grep -q "All tests passed\|Some tests failed\|Test failed\|run $n failed" "$log"; then
      adbs shell pkill -2 screenrecord >/dev/null 2>&1
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
  done
done
dart run tool/dev/map_gesture_summary.dart "$out"
exit $status
