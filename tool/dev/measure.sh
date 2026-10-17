#!/usr/bin/env bash
# Measures a commit on the phone from a separate worktree, so editing can go
# on here while `flutter drive` builds and runs (it compiles the working tree
# for every run).
#
#   tool/dev/measure.sh <label> [runs] [commit]     # commit defaults to HEAD
#   FLOWS=theme_switch tool/dev/measure.sh theme 3
#
# The worktree lives next to the repository (../later-measure, outside it) and
# gets the local-only Firebase and SDK config copied in (never committed).
# Results land in build/perf/<label>/ here, as with tool/dev/perf.sh.
set -e
repo=$(cd "$(dirname "$0")/../.." && pwd)
tree=${MEASURE_TREE:-$repo/../later-measure}
label=${1:?usage: measure.sh <label> [runs] [commit]}
runs=${2:-3}
commit=$(git -C "$repo" rev-parse "${3:-HEAD}")

if [ ! -d "$tree" ]; then
  git -C "$repo" worktree add --detach "$tree" "$commit" >/dev/null
fi
git -C "$tree" checkout -q --detach "$commit"
for f in android/app/google-services.json lib/firebase_options.dart android/local.properties; do
  cp "$repo/$f" "$tree/$f"
done
echo "measuring $(git -C "$tree" log -1 --format='%h %s') as '$label'"
(cd "$tree" && bash tool/dev/perf.sh "$label" "$runs")
mkdir -p "$repo/build/perf"
rm -rf "$repo/build/perf/$label"
cp -r "$tree/build/perf/$label" "$repo/build/perf/$label"
echo "copied to build/perf/$label"
