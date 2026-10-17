#!/usr/bin/env bash
# Local Firebase emulators for the app on a USB phone (docs/feel/RIG.md).
#
#   tool/dev/emulators.sh     # start Auth, Firestore, Storage, Functions
#
# Maps the emulator ports on the phone with `adb reverse`, so the app built
# with FIREBASE_EMULATOR_HOST=127.0.0.1 reaches this computer. The app calls
# no callable function, so the Functions port (5001) is mapped only for
# completeness; its Firestore triggers run on this computer. In the emulator
# the functions log pushes instead of sending them (functions/index.js).
# Seed it with `node tool/seed_heavy.js` once it is up.
source "$(dirname "$0")/env.sh"

for port in 9099 8080 9199 5001; do
  adbs reverse tcp:$port tcp:$port >/dev/null
done
adbs reverse --list
exec firebase emulators:start --project later-da778 --only auth,firestore,storage,functions
