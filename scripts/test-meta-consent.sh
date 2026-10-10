#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
WORK_DIR=$(mktemp -d /tmp/meta-consent-tests.XXXXXX)
trap 'rm -rf "$WORK_DIR"' EXIT
swiftc -module-cache-path "$WORK_DIR/cache" Dundaillereal/Config/MetaActivationGate.swift Tests/MetaActivationTests.swift -o "$WORK_DIR/meta-tests"
"$WORK_DIR/meta-tests"
python3 - <<'PYCONFIG'
import plistlib
from pathlib import Path
with open('Dundaillereal/Info.plist', 'rb') as f:
    info = plistlib.load(f)
for key in ['FacebookAutoLogAppEventsEnabled', 'FacebookAdvertiserIDCollectionEnabled', 'FacebookSKAdNetworkReportEnabled', 'FBSDKAemAutoSetupEnabled']:
    assert info[key] is False, key
with open('Dundaillereal/Config/PrivacyInfo.xcprivacy', 'rb') as f:
    privacy = plistlib.load(f)
assert privacy['NSPrivacyTracking'] is True
assert all(item['NSPrivacyCollectedDataType'] != 'NSPrivacyCollectedDataTypePurchaseHistory' for item in privacy['NSPrivacyCollectedDataTypes'])
for path in Path('Dundaillereal').rglob('*.swift'):
    code = path.read_text()
    assert 'logPurchase(' not in code, str(path)
    assert 'case .event(let event)' not in code, str(path)
print('PASS privacy settings disable automatic collection and remove purchase reporting')
PYCONFIG
