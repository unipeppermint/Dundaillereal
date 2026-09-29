#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
WORK_DIR=$(mktemp -d /tmp/web-bridge-tests.XXXXXX)
trap 'rm -rf "$WORK_DIR"' EXIT
swiftc -module-cache-path "$WORK_DIR/cache" Dundaillereal/Config/LaunchLinkService.swift Dundaillereal/Config/LaunchScriptBridge.swift Tests/ScriptBridgeTests.swift -o "$WORK_DIR/bridge-tests"
"$WORK_DIR/bridge-tests"
