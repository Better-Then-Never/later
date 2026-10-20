#!/usr/bin/env bash
# Builds the touch injector (Pinch.java, run with app_process as the shell
# user, like Android's own `input` command) and the animator scale check
# (AnimScale.java) into one jar and pushes it to the phone as
# /data/local/tmp/pinch.jar. Needs a JDK (Android Studio's) and the SDK.
source "$(dirname "$0")/../env.sh"
SDK=${ANDROID_SDK:-/d/AndroidSDK}
JAVAC=${JAVAC:-"/c/Program Files/Android/Android Studio/jbr/bin/javac.exe"}
ANDROID_JAR=$(ls -d "$SDK"/platforms/android-3[3-9]/android.jar | sort | tail -1)
D8=$(ls "$SDK"/build-tools/*/d8.bat 2>/dev/null | sort | tail -1)
out=build/dev/touch
mkdir -p "$out/classes"
"$JAVAC" -source 11 -target 11 -cp "$(cygpath -w "$ANDROID_JAR")" -d "$out/classes" \
  tool/dev/touch/Pinch.java tool/dev/touch/AnimScale.java || exit 1
cmd /c "$(cygpath -w "$D8")" --lib "$(cygpath -w "$ANDROID_JAR")" \
  --output "$(cygpath -w "$out")" "$(cygpath -w "$out/classes/Pinch.class")" \
  "$(cygpath -w "$out/classes/AnimScale.class")" || exit 1
(cd "$out" && rm -f pinch.jar && "/c/Program Files/Android/Android Studio/jbr/bin/jar.exe" cf pinch.jar classes.dex) || exit 1
adbs push "$out/pinch.jar" /data/local/tmp/pinch.jar >/dev/null
echo "pushed /data/local/tmp/pinch.jar"
