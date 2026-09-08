#!/usr/bin/env bash
# Run the JiuFlowUITests bundle on a physical iPhone and export screenshots/attachments.
#
#   scripts/ui-test-device.sh [DEVICE_UDID] [-only-testing:JiuFlowUITests/SmokeTests ...]
#
# - Signing is overridden to Automatic / Apple Development so the App Store (Manual) profiles
#   in project.yml are not required. Xcode must be signed into the 5BV85JW8US team.
# - The phone must be unlocked and in Developer Mode.
# - A watchdog interrupts xcodebuild after $TEST_MAX_S seconds (default 25 min) — a device that
#   never launches the test runner otherwise leaves xcodebuild waiting forever.
set -uo pipefail
cd "$(dirname "$0")/.."

DEVICE="${1:-00008140-0005453411E0801C}"; shift || true
TEST_MAX_S="${TEST_MAX_S:-1500}"
OUT="${OUT:-build/ui-test}"
STAMP="$(date +%Y%m%d-%H%M%S)"
RESULT="$OUT/$STAMP.xcresult"
LOG="$OUT/$STAMP.log"
mkdir -p "$OUT"

echo "▶ xcodebuild test → device $DEVICE (log: $LOG)"
xcodebuild -project JiuFlow.xcodeproj -scheme JiuFlow \
  -destination "id=$DEVICE" -derivedDataPath build \
  -allowProvisioningUpdates -allowProvisioningDeviceRegistration \
  CODE_SIGN_STYLE=Automatic CODE_SIGN_IDENTITY="Apple Development" PROVISIONING_PROFILE_SPECIFIER="" \
  -resultBundlePath "$RESULT" \
  -only-testing:JiuFlowUITests "$@" test > "$LOG" 2>&1 &
XB=$!
( sleep "$TEST_MAX_S"; if kill -0 $XB 2>/dev/null; then echo "WATCHDOG: xcodebuild exceeded ${TEST_MAX_S}s — interrupted" | tee -a "$LOG"; kill -INT $XB; sleep 15; kill -TERM $XB 2>/dev/null; fi ) &
WD=$!
wait $XB; RC=$?
kill $WD 2>/dev/null

echo "── summary (rc=$RC)"
grep -E "Test Suite '(All tests|JiuFlowUITests)'|Test Case .* (passed|failed|skipped)|Executed|error:|xcodebuild: error" "$LOG" | sed 's/^[^T]*Test Case/Test Case/' | tail -60

if [ -d "$RESULT" ]; then
  ATT="$OUT/$STAMP-attachments"
  mkdir -p "$ATT"
  # Xcode 16: export every attachment (screenshots, text dumps) with a manifest of original names.
  xcrun xcresulttool export attachments --path "$RESULT" --output-path "$ATT" >/dev/null 2>&1 || true
  if [ -f "$ATT/manifest.json" ]; then
    python3 - "$ATT" <<'EOF'
import json, os, sys, shutil
d = sys.argv[1]
m = json.load(open(os.path.join(d, "manifest.json")))
n = 0
for t in m:
    tid = t.get("testIdentifier", "").replace("/", "__").replace("()", "")
    for a in t.get("attachments", []):
        src = os.path.join(d, a["exportedFileName"]); name = a.get("suggestedHumanReadableName") or a["exportedFileName"]
        ext = os.path.splitext(a["exportedFileName"])[1]
        dst = os.path.join(d, f"{name}{'' if name.endswith(ext) else ext}")
        if os.path.exists(src) and src != dst:
            shutil.move(src, dst); n += 1
print(f"exported {n} attachments → {d}")
EOF
  fi
  ls "$ATT" | head -80
fi
exit $RC
