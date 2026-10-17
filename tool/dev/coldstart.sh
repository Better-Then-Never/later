#!/usr/bin/env bash
# Cold start of the profile app on the USB phone: N launches, the app
# force-stopped before each, signed in (as a returning user).
#
#   tool/dev/coldstart.sh [launches] [--no-build]
#
# Per launch it prints Android's two numbers:
#   first frame  `am start -W` TotalTime: process start to the first frame
#                (Flutter holds Android's first draw until its own first frame)
#   home         logcat "Fully drawn": process start to the first frame of the
#                signed-in home screen (StartupReport → reportFullyDrawn)
# and the medians; saved to build/perf/coldstart.txt.
source "$(dirname "$0")/env.sh"

launches=${1:-5}
if [ "$2" != "--no-build" ]; then
  flutter build apk --profile "${DEFINES[@]}" >"$DEV_DIR/coldstart_build.log" 2>&1 ||
    { tail -n 20 "$DEV_DIR/coldstart_build.log"; exit 1; }
  adbs install -r build/app/outputs/flutter-apk/app-profile.apk >/dev/null || exit 1
fi
for permission in CAMERA ACCESS_FINE_LOCATION ACCESS_COARSE_LOCATION POST_NOTIFICATIONS; do
  adbs shell pm grant "$APP_ID" android.permission.$permission >/dev/null 2>&1
done

# A first launch so sign-in and caches are warm.
adbs shell am force-stop "$APP_ID"
adbs shell am start -W -n "$APP_ID/.MainActivity" >/dev/null
sleep 10

ms() { # "+1s234ms" or "+987ms" → milliseconds
  awk '{ s = $0; sub(/^\+/, "", s); t = 0
    if (match(s, /^[0-9]+s/)) { t = substr(s, 1, RLENGTH - 1) * 1000; s = substr(s, RLENGTH + 1) }
    if (match(s, /^[0-9]+ms/)) t += substr(s, 1, RLENGTH - 2)
    print t }'
}
median() { sort -n | awk '{ a[NR] = $1 } END { print a[int((NR + 1) / 2)] }'; }

mkdir -p build/perf
: >build/perf/coldstart.txt
for n in $(seq "$launches"); do
  adbs shell am force-stop "$APP_ID"
  sleep 3
  adbs logcat -c
  first=$(adbs shell am start -W -n "$APP_ID/.MainActivity" | tr -d '\r' | awk -F': ' '/TotalTime/ { print $2 }')
  sleep 8
  home=$(adbs logcat -d | tr -d '\r' | grep -m1 "Fully drawn $APP_ID" | grep -oE '\+[0-9]+s?[0-9]*ms|\+[0-9]+s' | head -1 | ms)
  echo "launch $n: first frame ${first} ms, home ${home:-?} ms" | tee -a build/perf/coldstart.txt
done
{
  echo "median first frame: $(awk '/launch/ { sub(/ ms,.*/, "", $5); print $5 }' build/perf/coldstart.txt | median) ms"
  echo "median home: $(awk '/launch/ { print $8 }' build/perf/coldstart.txt | grep -v '?' | median) ms"
} | tee -a build/perf/coldstart.txt
