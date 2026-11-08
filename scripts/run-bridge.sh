#!/bin/sh
set -e
. "$(dirname "$0")/java-env.sh"
cd "$ROOT/bridge"
./gradlew -q installDist
exec ./build/install/xmage-bridge/bin/xmage-bridge --decks "$XMAGE_HOME/mage-client/sample-decks" "$@"
