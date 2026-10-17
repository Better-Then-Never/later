#!/usr/bin/env bash
# One screenshot of the phone, downscaled to 540 px wide (about a quarter of
# the pixels), for checking looks. Prints the file path.
#
#   tool/dev/shot.sh name        # build/dev/shots/name.png
source "$(dirname "$0")/env.sh"

name=${1:-shot}
mkdir -p "$DEV_DIR/shots"
full=$DEV_DIR/shots/${name}_full.png
out=$DEV_DIR/shots/$name.png
adbs exec-out screencap -p >"$full"
dart run tool/dev/downscale.dart "$full" "$out" 540 && rm -f "$full"
echo "$out"
