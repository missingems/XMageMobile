#!/bin/sh
set -e
. "$(dirname "$0")/java-env.sh"
cd "$XMAGE_HOME/mage-server"
exec "$JAVA" -Xmx2048m -Dfile.encoding=UTF-8 $OPENS -jar "./lib/mage-server-${XMAGE_VERSION}.jar"
