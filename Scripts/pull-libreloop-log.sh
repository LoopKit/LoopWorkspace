#!/bin/sh
# Pulls LibreLoop's rolling log file from Pete's iPhone.
# Outputs to /tmp/libreloop-log/.
#
# Requires a dev build of Loop installed (get-task-allow entitlement).
# Honors LIBRELOOP_DEVICE_ID and LIBRELOOP_BUNDLE_ID for override.

DEVICE="${LIBRELOOP_DEVICE_ID:-4950044E-6D03-564F-A1D9-E86E77D99613}"
BUNDLE="${LIBRELOOP_BUNDLE_ID:-com.UY678SP37Q.loopkit.Loop}"
DEST="${1:-/tmp/libreloop-log}"

rm -rf "$DEST"
mkdir -p "$DEST"
xcrun devicectl device copy from \
  --device "$DEVICE" \
  --domain-type appDataContainer \
  --domain-identifier "$BUNDLE" \
  --source Documents/libreloop \
  --destination "$DEST" \
  "$@" >/dev/null 2>&1

if [ -f "$DEST/libreloop/log.txt" ]; then
  echo "Pulled $(wc -l < "$DEST/libreloop/log.txt") lines to $DEST/libreloop/log.txt"
  [ -f "$DEST/libreloop/log.1.txt" ] && echo "Plus rotated log $DEST/libreloop/log.1.txt"
else
  echo "No log file found at $DEST/libreloop/log.txt"
  ls -la "$DEST" 2>/dev/null
  exit 1
fi
