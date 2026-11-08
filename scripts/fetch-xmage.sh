#!/bin/sh
set -e
. "$(dirname "$0")/java-env.sh"
TAG="xmage_${XMAGE_VERSION}V1"
mkdir -p "$ROOT/vendor"
cd "$ROOT/vendor"
URL=$(gh api "repos/magefree/mage/releases/tags/$TAG" --jq '.assets[0].browser_download_url')
echo "Downloading $URL"
curl -fL -o "mage-full_${XMAGE_VERSION}.zip" "$URL"
rm -rf xmage && mkdir xmage
ditto -x -k "mage-full_${XMAGE_VERSION}.zip" xmage
sed -i '' 's/<server serverAddress="0.0.0.0"/<server serverAddress="127.0.0.1"/' xmage/xmage/mage-server/config/config.xml
echo "XMage $XMAGE_VERSION unpacked into vendor/xmage"
