#!/usr/bin/env bash
# App Store 用スクショを en / pt でシミュレータ撮影し、xcresult から書き出す。
# 実機は iOS26.5.2×Xcode16.2 でテストランナーが起動しない → シミュレータを使う。
#
#   scripts/appstore_shots.sh            # iPhone 16 Pro Max(6.9")を作って撮影
#   OUT=build/shots scripts/appstore_shots.sh
set -uo pipefail
cd "$(dirname "$0")/.."
OUT="${OUT:-build/shots}"; mkdir -p "$OUT"
UD="${SIM_UDID:-$(xcrun simctl create JiuFlow-Shots "iPhone 16 Pro Max" "com.apple.CoreSimulator.SimRuntime.iOS-18-3")}"
echo "▶ sim $UD"
xcrun simctl bootstatus "$UD" -b >/dev/null 2>&1
RESULT="$OUT/shots.xcresult"; rm -rf "$RESULT"
xcodebuild -project JiuFlow.xcodeproj -scheme JiuFlow -destination "id=$UD" \
  -derivedDataPath build-sim CODE_SIGNING_ALLOWED=NO -resultBundlePath "$RESULT" \
  -only-testing:JiuFlowUITests/AppStoreShots test
ATT="$OUT/attachments"; rm -rf "$ATT"; mkdir -p "$ATT"
xcrun xcresulttool export attachments --path "$RESULT" --output-path "$ATT" >/dev/null 2>&1
python3 - "$ATT" <<'PY'
import json,os,sys,shutil
d=sys.argv[1]; m=json.load(open(os.path.join(d,'manifest.json'))); n=0
for t in m:
    for a in t.get('attachments',[]):
        src=os.path.join(d,a['exportedFileName']); name=a.get('suggestedHumanReadableName') or a['exportedFileName']
        if not name.lower().endswith('.png'): name+='.png'
        dst=os.path.join(d,name)
        if os.path.exists(src) and src!=dst: shutil.move(src,dst); n+=1
print('exported',n,'→',d)
PY
ls "$ATT"/*.png
