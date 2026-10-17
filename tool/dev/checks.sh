#!/usr/bin/env bash
# The local quality gates (PR #79 has no CI: pr-build.yml runs only for PRs
# into main). Stops at the first failure and prints one line per check;
# no pipes hide an exit code.
#
#   tool/dev/checks.sh            # format, analyze, tests, tokens, l10n
#
# Rules and functions tests need the emulators: see docs/feel/FEEL_QA.md.
cd "$(dirname "$0")/../.." || exit 1
mkdir -p build/dev
log=build/dev/checks.log
run() {
  local name="$1"
  shift
  if "$@" >"$log" 2>&1; then
    echo "ok   $name"
  else
    echo "FAIL $name"
    tail -n 20 "$log"
    exit 1
  fi
}
run format dart format --output=none --set-exit-if-changed lib test tool integration_test test_driver
run analyze flutter analyze
run tests flutter test
tail -n 1 "$log" | tr -d '\r' | sed 's/^/     /'
run tokens dart run tool/check_design_tokens.dart
unused=$(node tool/l10n/unused_keys.js)
if [ "$unused" = "none" ]; then echo "ok   l10n unused"; else echo "FAIL l10n unused: $unused"; exit 1; fi
