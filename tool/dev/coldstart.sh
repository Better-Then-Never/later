#!/usr/bin/env bash
# Cold start of the profile app on the USB phone (docs/map/COLD_START.md):
# N launches, the app force-stopped before each, signed in (a returning
# user), launched as from the home screen (the splash screen with its icon).
#
#   tool/dev/coldstart.sh [launches] [--no-build] [label]
#   VIDEO=1 tool/dev/coldstart.sh 5 --no-build base   # also films launch 1
#
# Per launch, milliseconds from Android's launch of the activity (the moment
# it counts "Displayed" and "Fully drawn" from):
#   ttid     first frame (am start -W TotalTime; Flutter holds Android's first
#            draw until its own first frame)
#   shell    the map page's buttons drawn over its cover
#   streets  the map idle for the first time: style and tiles drawn
#   own/all  the capsule sources answered: own, then all four
#   pins     the first pins drawn; full: every pin of this start drawn
#            (Activity.reportFullyDrawn, logcat "Fully drawn": TTFD)
#   jank     frames over 8.3 ms (build or raster) from the first frame to
#            two seconds after full, and the worst one
# and the medians; saved to build/perf/coldstart_<label>.txt. The marks are
# the app's LATERSTART log lines (lib/app/shell/startup_report.dart).
source "$(dirname "$0")/env.sh"

launches=${1:-5}
label=${3:-latest}
if [ "$2" != "--no-build" ]; then
  flutter build apk --profile "${DEFINES[@]}" >"$DEV_DIR/coldstart_build.log" 2>&1 ||
    { tail -n 20 "$DEV_DIR/coldstart_build.log"; exit 1; }
  # The Gradle daemon holds gigabytes; the wrapper fails with the path
  # conversion off (env.sh), so it is back on for this.
  (unset MSYS_NO_PATHCONV; cd android && ./gradlew --stop >/dev/null 2>&1)
  adbs install -r build/app/outputs/flutter-apk/app-profile.apk >/dev/null || exit 1
fi
for permission in CAMERA ACCESS_FINE_LOCATION ACCESS_COARSE_LOCATION POST_NOTIFICATIONS; do
  adbs shell pm grant "$APP_ID" android.permission.$permission >/dev/null 2>&1
done

launch() {
  adbs shell am start -W --splashscreen-show-icon -n "$APP_ID/.MainActivity" |
    tr -d '\r' | awk -F': ' '/TotalTime/ { print $2 }'
}

# A first launch so sign-in and caches are warm.
adbs shell am force-stop "$APP_ID"
launch >/dev/null
sleep 12

mkdir -p build/perf "$DEV_DIR/coldstart"
out=build/perf/coldstart_$label.txt
: >"$out"
for n in $(seq "$launches"); do
  adbs shell am force-stop "$APP_ID"
  sleep 3
  adbs logcat -c
  if [ -n "$VIDEO" ] && [ "$n" = 1 ]; then
    adbs shell rm -f /sdcard/coldstart.mp4
    (adbs shell screenrecord --size 540x1200 --bit-rate 12000000 --time-limit 10 \
      /sdcard/coldstart.mp4 >/dev/null 2>&1 &)
    sleep 0.8
  fi
  ttid=$(launch)
  # Until the frame summary (two seconds after full), at most 20 s.
  for _ in $(seq 40); do
    adbs logcat -d | grep -q "LATERSTART frames" && break
    sleep 0.5
  done
  log="$DEV_DIR/coldstart/${label}_$n.log"
  adbs logcat -d -v epoch >"$log"
  node tool/dev/coldstart_report.js launch "$n" "$ttid" "$log" | tee -a "$out"
  if [ -n "$VIDEO" ] && [ "$n" = 1 ]; then
    sleep 8
    mkdir -p build/dev/video
    adbs pull /sdcard/coldstart.mp4 "build/dev/video/coldstart_$label.mp4" >/dev/null 2>&1
  fi
done
node tool/dev/coldstart_report.js medians "$out" | tee -a "$out"
