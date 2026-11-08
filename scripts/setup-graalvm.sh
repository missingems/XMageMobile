#!/bin/sh
# Downloads GraalVM CE and the matching graalvm-mobile iOS kits into vendor/toolchains (checksums verified).
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GRAAL_TAG=graal-25.5.5.0.3
GRAAL_ASSET=graalvm-community-jdk-25i5-25.0.5.0.3_macos-aarch64_bin.tar.gz
KIT_TAG=graalvm-mobile-25.5.5.0.3b1.1
T="$ROOT/vendor/toolchains"
mkdir -p "$T/dl"
cd "$T/dl"
gh release download "$GRAAL_TAG" -R graalvm/graalvm-ce-builds -p "$GRAAL_ASSET*" --clobber
gh release download "$KIT_TAG" -R NucleusFramework/graalvm-mobile -p "*ios-*" --clobber
for f in *.sha256; do
  [ "$(awk '{print $1}' "$f")" = "$(shasum -a 256 "${f%.sha256}" | awk '{print $1}')" ] || { echo "Checksum mismatch: ${f%.sha256}"; exit 1; }
done
tar -xzf "$GRAAL_ASSET" -C "$T"
mkdir -p "$T/kit-sim" "$T/kit-device"
tar -xzf graalvm-mobile-*-ios-simulator-aarch64-*.tar.gz -C "$T/kit-sim"
tar -xzf graalvm-mobile-*-ios-device-aarch64-*.tar.gz -C "$T/kit-device"
echo "GraalVM and iOS kits are in $T"
