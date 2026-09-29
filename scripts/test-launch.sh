#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
WORK_DIR=$(mktemp -d /tmp/launch-link-tests.XXXXXX)
trap 'rm -rf "$WORK_DIR"' EXIT
swiftc -module-cache-path "$WORK_DIR/cache" Dundaillereal/Config/LaunchLinkService.swift Tests/LaunchLinkTests.swift -o "$WORK_DIR/launch-tests"
"$WORK_DIR/launch-tests"
