#!/usr/bin/env bash
# Recreates the git-ignored Firebase config files (and the iOS Maps key) from
# GitHub Actions secrets. Usage: tools/ci/write-config.sh android|ios
# Secrets are described in docs/CI.md.
set -euo pipefail

platform="${1:?usage: write-config.sh android|ios}"

need() {
  if [ -z "${!1:-}" ]; then
    echo "::error::GitHub secret $1 is not set (see docs/CI.md)"
    exit 1
  fi
}

decode() { printf '%s' "$1" | base64 --decode > "$2"; }

need FIREBASE_OPTIONS_DART_BASE64
decode "$FIREBASE_OPTIONS_DART_BASE64" lib/firebase_options.dart

case "$platform" in
  android)
    need GOOGLE_SERVICES_JSON_BASE64
    decode "$GOOGLE_SERVICES_JSON_BASE64" android/app/google-services.json
    # The Android Maps key is passed to Gradle as MAPS_API_KEY (env).
    ;;
  ios)
    need GOOGLE_SERVICE_INFO_PLIST_BASE64
    decode "$GOOGLE_SERVICE_INFO_PLIST_BASE64" ios/Runner/GoogleService-Info.plist
    if [ -n "${MAPS_API_KEY_IOS:-}" ]; then
      printf 'GMS_API_KEY=%s\n' "$MAPS_API_KEY_IOS" > ios/Flutter/Secrets.xcconfig
    fi
    ;;
  *)
    echo "unknown platform: $platform" >&2
    exit 1
    ;;
esac

echo "Wrote Firebase config for $platform."
