#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
WORK_DIR=$(mktemp -d /tmp/dicework-tests.XXXXXX)
trap 'rm -rf "$WORK_DIR"' EXIT
swiftc -module-cache-path "$WORK_DIR/cache" Dundaillereal/Domain/Game.swift Dundaillereal/Data/Store.swift Tests/RuleTests.swift -o "$WORK_DIR/rule-tests"
"$WORK_DIR/rule-tests"
