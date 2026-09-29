#!/bin/sh
# Read-only verification of an exported, signed iOS app or IPA before submission.
set -eu
fail() { printf '%s\n' "FAIL: $*" >&2; exit 1; }
[ "$#" -eq 1 ] || fail "Usage: sh scripts/verify-production-push.sh /path/to/App.ipa (or App.app)"
VERIFY_DIR=$(mktemp -d /tmp/production-push-check.XXXXXX)
trap 'rm -rf "$VERIFY_DIR"' EXIT
case "$1" in
    *.ipa)
        [ -f "$1" ] || fail "IPA not found"
        /usr/bin/ditto -x -k "$1" "$VERIFY_DIR/unpacked"
        set -- "$VERIFY_DIR"/unpacked/Payload/*.app
        [ "$#" -eq 1 ] || fail "Expected exactly one application in IPA"
        APP_PATH=$1
        ;;
    *.app) APP_PATH=$1 ;;
    *) fail "Expected an exported .ipa or .app" ;;
esac
[ -d "$APP_PATH" ] || fail "Application not found"
/usr/bin/codesign --verify --strict "$APP_PATH" || fail "Invalid app signature"
/usr/bin/codesign -d --entitlements :- "$APP_PATH" > "$VERIFY_DIR/entitlements.plist" 2>/dev/null || fail "Cannot read signed entitlements"
APS_VALUE=$(/usr/libexec/PlistBuddy -c 'Print :aps-environment' "$VERIFY_DIR/entitlements.plist")
[ "$APS_VALUE" = production ] || fail "Signed aps-environment must be production (found: $APS_VALUE)"
TASK_ALLOWED=$(/usr/libexec/PlistBuddy -c 'Print :get-task-allow' "$VERIFY_DIR/entitlements.plist" 2>/dev/null || true)
[ "$TASK_ALLOWED" != true ] || fail "App signature allows debugging"
APP_ID=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$APP_PATH/Info.plist")
FIREBASE_ID=$(/usr/libexec/PlistBuddy -c 'Print :BUNDLE_ID' "$APP_PATH/GoogleService-Info.plist")
[ "$APP_ID" = "$FIREBASE_ID" ] || fail "App Bundle ID does not match Firebase configuration"
[ -f "$APP_PATH/embedded.mobileprovision" ] || fail "Exported app is missing its provisioning profile"
/usr/bin/security cms -D -i "$APP_PATH/embedded.mobileprovision" > "$VERIFY_DIR/profile.plist"
PROFILE_APS=$(/usr/libexec/PlistBuddy -c 'Print :Entitlements:aps-environment' "$VERIFY_DIR/profile.plist")
[ "$PROFILE_APS" = production ] || fail "Provisioning profile must enable production APNs"
TEAM_ID=$(/usr/libexec/PlistBuddy -c 'Print :com.apple.developer.team-identifier' "$VERIFY_DIR/entitlements.plist")
SIGNED_APP_ID=$(/usr/libexec/PlistBuddy -c 'Print :application-identifier' "$VERIFY_DIR/entitlements.plist")
PROFILE_APP_ID=$(/usr/libexec/PlistBuddy -c 'Print :Entitlements:application-identifier' "$VERIFY_DIR/profile.plist")
[ "$SIGNED_APP_ID" = "$PROFILE_APP_ID" ] || fail "Signed app identifier differs from provisioning profile"
case "$SIGNED_APP_ID" in *."$APP_ID") ;; *) fail "Signed app identifier does not match Bundle ID" ;; esac
PROFILE_TEAM=$(/usr/libexec/PlistBuddy -c 'Print :Entitlements:com.apple.developer.team-identifier' "$VERIFY_DIR/profile.plist")
[ "$TEAM_ID" = "$PROFILE_TEAM" ] || fail "Signed team differs from provisioning profile"
printf '%s\n' "PASS: production APNs, signed app identity, profile and Firebase Bundle ID checks passed."
printf '%s\n' "This verifies packaging only; APNs credentials and delivery still require service-side validation."
