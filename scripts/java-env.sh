#!/bin/sh
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
XMAGE_VERSION="$(grep '^xmageVersion=' "$ROOT/bridge/gradle.properties" | cut -d= -f2)"
XMAGE_HOME="${XMAGE_HOME:-$ROOT/vendor/xmage/xmage}"
if [ -z "$JAVA_HOME" ] && [ -d /opt/homebrew/opt/openjdk@21 ]; then
  JAVA_HOME=/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home
fi
JAVA="${JAVA_HOME:+$JAVA_HOME/bin/}java"
OPENS=""
for pkg in java.io java.lang java.lang.reflect java.util java.util.concurrent java.util.concurrent.atomic java.net java.text sun.nio.ch java.math java.time; do
  OPENS="$OPENS --add-opens=java.base/$pkg=ALL-UNNAMED"
done
export ROOT XMAGE_VERSION XMAGE_HOME JAVA_HOME JAVA OPENS
