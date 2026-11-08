#!/bin/sh
# Compiles the bridge (with XMage's client classes) to native iOS code and packages
# app/Frameworks/XMageBridge.xcframework for the app. Needs scripts/setup-graalvm.sh first.
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$ROOT/scripts/java-env.sh"
T="$ROOT/vendor/toolchains"
GRAAL="$(ls -d "$T"/graalvm-community-*/Contents/Home | head -1)"
[ -x "$GRAAL/bin/native-image" ] || { echo "Run scripts/setup-graalvm.sh first"; exit 1; }
LIB="$XMAGE_HOME/mage-client/lib"
OUT="$ROOT/vendor/ios-build"

(cd "$ROOT/bridge" && ./gradlew -q jar)
CP="$ROOT/bridge/build/libs/xmage-bridge.jar"
for j in mage-common mage jspf-core jboss-remoting jboss-common-core jboss-serialization jboss-logging-spi prettytime \
         concurrent trove-1 commons-lang3 guava failureaccess gson jsoup protobuf-java reload4j slf4j-api-2.0.17 slf4j-reload4j commons-logging; do
  for f in "$LIB"/$j*.jar; do CP="$CP:$f"; break; done
done

OPENS=""
for pkg in java.io java.lang java.lang.reflect java.util java.util.concurrent java.util.concurrent.atomic java.net java.text sun.nio.ch java.math java.time; do
  OPENS="$OPENS --add-opens=java.base/$pkg=ALL-UNNAMED"
done

for target in sim device; do
  KIT="$T/kit-$target"
  prop() { sed -n "s/^$1=//p" "$KIT/graalvm-mobile.properties"; }
  rm -rf "$OUT/$target"
  mkdir -p "$OUT/$target/headers"
  "$GRAAL/bin/native-image" -cp "$CP" \
    -H:+UnlockExperimentalVMOptions -H:ConfigurationFileDirectories="$ROOT/bridge/native/traced,$ROOT/bridge/native/serialization" \
    -Dsvm.platform="$(prop native-image.platform)" $(prop native-image.flags) \
    $OPENS -H:IncludeResources=log4j.properties -Dfile.encoding=UTF-8 -R:MaxHeapSize=512m \
    -H:+SharedLibrary -H:+ExitAfterRelocatableImageWrite -H:TempDirectory="$OUT/$target/tmp" \
    -o "$OUT/$target/xmagebridge"
  OBJ="$(find "$OUT/$target/tmp" -name xmagebridge.o | head -1)"
  libtool -static -o "$OUT/$target/libXMageBridge.a" "$OBJ" "$KIT"/lib/*.a 2>/dev/null
  cp "$OUT/$target/xmagebridge.h" "$OUT/$target/graal_isolate.h" "$OUT/$target/headers/"
  cat > "$OUT/$target/headers/module.modulemap" <<'MAP'
module XMageBridge {
    header "xmagebridge.h"
    export *
}
MAP
done

rm -rf "$ROOT/app/Frameworks/XMageBridge.xcframework"
mkdir -p "$ROOT/app/Frameworks"
xcodebuild -create-xcframework \
  -library "$OUT/device/libXMageBridge.a" -headers "$OUT/device/headers" \
  -library "$OUT/sim/libXMageBridge.a" -headers "$OUT/sim/headers" \
  -output "$ROOT/app/Frameworks/XMageBridge.xcframework"
echo "Built app/Frameworks/XMageBridge.xcframework"
