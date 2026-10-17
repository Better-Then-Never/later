#!/usr/bin/env bash
# Profile-mode frame timings of the key flows on the USB phone
# (integration_test/perf_test.dart), several runs in a row.
#
#   tool/dev/perf.sh <label> [runs]      # e.g. tool/dev/perf.sh baseline 3
#   FLOWS=chat_open,map_pan tool/dev/perf.sh chat 3   # only these flows
#   KEEP_TIMELINE=1 DETAIL=1 FLOWS=theme_switch tool/dev/perf.sh why 1
#       # keeps <flow>.timeline.json with an event per widget build, layout
#       # and paint, for tool/dev/slow_frames.dart (DETAIL slows frames down:
#       # its numbers are for finding causes, not for PERFORMANCE.md)
#
# Each run lands in build/perf/<label>/run_<n>/: one
# <flow>.timeline_summary.json per flow (per-frame build and raster times),
# perf_numbers.json (timestamps the test measured itself), gfxinfo.txt and
# timestats.txt (what Android saw for the whole run). Summarise with
#   dart run tool/dev/perf_summary.dart build/perf/<label>
source "$(dirname "$0")/env.sh"

label=${1:?usage: perf.sh <label> [runs]}
runs=${2:-3}
out=build/perf/$label
mkdir -p "$out"

for n in $(seq "$runs"); do
  dir=$out/run_$n
  rm -rf "$dir"
  mkdir -p "$dir"
  rm -f build/*.timeline_summary.json build/*.timeline.json build/perf_numbers.json
  # No system permission dialog in the middle of a flow (kept across the
  # reinstall; fails harmlessly before the first install).
  for permission in CAMERA ACCESS_FINE_LOCATION ACCESS_COARSE_LOCATION POST_NOTIFICATIONS; do
    adbs shell pm grant "$APP_ID" android.permission.$permission >/dev/null 2>&1
  done
  adbs shell dumpsys SurfaceFlinger --timestats -disable >/dev/null
  adbs shell dumpsys SurfaceFlinger --timestats -clear >/dev/null
  adbs shell dumpsys SurfaceFlinger --timestats -enable >/dev/null
  echo "== $label run $n/$runs"
  flutter drive --profile -d "$DEVICE" \
    --driver=test_driver/perf_driver.dart \
    --target=integration_test/perf_test.dart \
    --keep-app-running --no-dds \
    "${DEFINES[@]}" \
    ${FLOWS:+--dart-define=PERF_FLOWS=$FLOWS} \
    ${DETAIL:+--dart-define=PERF_DETAIL=true} \
    >"$dir/drive.log" 2>&1
  status=$?
  # flutter drive can exit 0 although the test on the phone failed.
  if grep -q "Some tests failed\|Test failed" "$dir/drive.log"; then status=1; fi
  adbs shell dumpsys gfxinfo "$APP_ID" framestats >"$dir/gfxinfo.txt"
  adbs shell dumpsys SurfaceFlinger --timestats -dump >"$dir/timestats.txt"
  adbs shell dumpsys SurfaceFlinger --timestats -disable >/dev/null
  adbs shell am force-stop "$APP_ID"
  mv build/*.timeline_summary.json "$dir/" 2>/dev/null
  mv build/perf_numbers.json "$dir/" 2>/dev/null
  if [ -n "$KEEP_TIMELINE" ]; then
    mv build/*.timeline.json "$dir/" 2>/dev/null
  else
    rm -f build/*.timeline.json
  fi
  if [ $status -ne 0 ]; then
    echo "run $n failed (exit $status); see $dir/drive.log" >&2
    tail -n 20 "$dir/drive.log" >&2
    exit $status
  fi
  # A short rest so the phone does not heat up between runs.
  sleep 20
done
echo "done: $out"
