#!/usr/bin/env bash
# The phone's screen as text: every visible label with its bounds (from a
# uiautomator dump), plus the app's recent log lines. Cheaper than a
# screenshot when the question is "what is on screen?".
#
#   tool/dev/screen.sh          # texts and content descriptions
#   tool/dev/screen.sh --log    # also the last 30 lines of the app's log
source "$(dirname "$0")/env.sh"

adbs shell uiautomator dump /sdcard/window.xml >/dev/null 2>&1
adbs exec-out cat /sdcard/window.xml >"$DEV_DIR/window.xml"
node -e '
  const xml = require("fs").readFileSync(process.argv[1], "utf8");
  const nodes = xml.match(/<node [^>]*>/g) || [];
  for (const n of nodes) {
    const get = (k) => (n.match(new RegExp(" " + k + "=\"([^\"]*)\"")) || [])[1] || "";
    const label = get("text") || get("content-desc");
    if (!label) continue;
    const flags = [get("clickable") === "true" ? "tap" : "", get("scrollable") === "true" ? "scroll" : ""]
      .filter(Boolean).join(",");
    console.log(get("bounds").padEnd(28), label.replace(/\n/g, " ⏎ "), flags ? `[${flags}]` : "");
  }
' "$DEV_DIR/window.xml"

if [ "$1" = "--log" ]; then
  pid=$(adbs shell pidof "$APP_ID" | tr -d '\r')
  [ -n "$pid" ] && adbs logcat -d --pid="$pid" -t 30
fi
