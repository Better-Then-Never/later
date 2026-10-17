#!/usr/bin/env bash
# Tap targets of the screen on the phone, from the accessibility tree (what
# Flutter exposes as semantics): every tappable element smaller than 44 dp in
# either direction, and every one that reaches under the navigation pill.
#
#   tool/dev/tap_audit.sh [name]    # prints the findings; the dump is kept in
#                                   # build/dev/audit/<name>.xml
source "$(dirname "$0")/env.sh"

name=${1:-screen}
mkdir -p "$DEV_DIR/audit"
density=$(adbs shell wm density | tr -d '\r' | awk '{ v = $NF } END { print v / 160 }')
adbs shell uiautomator dump /sdcard/window.xml >/dev/null 2>&1
adbs exec-out cat /sdcard/window.xml >"$DEV_DIR/audit/$name.xml"
node - "$DEV_DIR/audit/$name.xml" "$density" <<'EOF'
const [file, density] = process.argv.slice(2);
const xml = require('fs').readFileSync(file, 'utf8');
const nodes = (xml.match(/<node [^>]*>/g) || []).map((n) => {
  const get = (k) => (n.match(new RegExp(' ' + k + '="([^"]*)"')) || [])[1] || '';
  const [x1, y1, x2, y2] = get('bounds').match(/\d+/g).map(Number);
  return {
    label: (get('text') || get('content-desc')).replace(/\n/g, ' ⏎ ').slice(0, 50),
    pkg: get('package'),
    tap: get('clickable') === 'true' || get('long-clickable') === 'true',
    x1, y1, x2, y2,
  };
});
const app = nodes.filter((n) => n.pkg === 'com.btn.later');
const dp = (px) => Math.round(px / Number(density));
const screenH = Math.max(...nodes.map((n) => n.y2));
// The pill: the row of tappable elements nearest the bottom of the screen.
const bottomRow = app.filter((n) => n.tap && n.y1 > screenH * 0.85);
const pillTop = bottomRow.length >= 4 ? Math.min(...bottomRow.map((n) => n.y1)) : null;
let problems = 0;
for (const n of app.filter((n) => n.tap)) {
  const w = dp(n.x2 - n.x1);
  const h = dp(n.y2 - n.y1);
  const flags = [];
  if (w < 44 || h < 44) flags.push(`small ${w}×${h} dp`);
  if (pillTop != null && !bottomRow.includes(n) && n.y2 > pillTop && n.y1 < pillTop) {
    flags.push(`under the pill by ${dp(n.y2 - pillTop)} dp`);
  }
  if (flags.length) {
    problems++;
    console.log(`${flags.join(', ').padEnd(34)} [${n.x1},${n.y1}][${n.x2},${n.y2}] ${n.label || '(no label)'}`);
  }
}
console.log(problems ? `${problems} problem(s)` : 'no tap target problems');
EOF
