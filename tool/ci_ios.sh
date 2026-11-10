#!/usr/bin/env bash
# بناء «قطعة سيارتك» لـiOS ورفعه إلى TestFlight
# Issuer ID و Key ID مثبّتان هنا (ليسا سريين) — السر الوحيد المطلوب هو محتوى ملف .p8
# الأرشفة بدون توقيع، والتوقيع للتوزيع يتم وقت التصدير (Cloud-managed) — لا يحتاج أجهزة مسجّلة
set -euo pipefail
cd "$(dirname "$0")/.."

TEAM_ID="5V6TC85KRL"
BUNDLE_ID="sa.almubarky.qitaat"
DEFAULT_ISSUER="3aa57344-99da-4421-94f9-5aaf95c16287"
DEFAULT_KEY_ID="DBJJJFNTJ5"
LOG=/tmp/qitaat-ci.log
: > "$LOG"
exec > >(tee -a "$LOG") 2>&1

# ── تقرير تلقائي: يُرفع آخر سجل إلى فرع ci-logs ليقرأه Claude مباشرة ──
report() {
  local code=$?
  set +e
  sleep 1
  if [ -n "${GITHUB_WORKSPACE:-}" ]; then
    local extra url d
    extra=$(git -C "$GITHUB_WORKSPACE" config --get http.https://github.com/.extraheader)
    url=$(git -C "$GITHUB_WORKSPACE" remote get-url origin)
    d=$(mktemp -d)
    tail -n 800 "$LOG" > "$d/last-ios.log"
    echo "run=${GITHUB_RUN_NUMBER:-?} exit=$code $(date -u '+%Y-%m-%d %H:%M UTC')" > "$d/status.txt"
    (
      cd "$d" &&
      git init -q &&
      git checkout -q -b ci-logs &&
      git add . &&
      git -c user.name=qitaat-ci -c user.email=ci@qitaat.local commit -qm "CI run ${GITHUB_RUN_NUMBER:-?} exit $code" &&
      git -c http.https://github.com/.extraheader="$extra" push -qf "$url" ci-logs
    ) || echo "⚠️ تعذّر رفع السجل"
  fi
  exit $code
}
trap report EXIT

step() { echo; echo "==================== $* ===================="; }

step "Xcode"
XC=$(ls -d /Applications/Xcode_26* 2>/dev/null | sort -V | tail -1 || true)
if [ -n "$XC" ]; then sudo xcode-select -s "$XC/Contents/Developer"; fi
xcodebuild -version

step "مفتاح App Store Connect"
if [ -z "${APP_STORE_CONNECT_KEY:-}" ]; then echo "❌ السر APP_STORE_CONNECT_KEY غير موجود في إعدادات مستودع qitaat"; exit 1; fi
KEY_ID=$(printf '%s' "${APP_STORE_CONNECT_KEY_ID:-$DEFAULT_KEY_ID}" | tr -d '[:space:]')
ISSUER=$(printf '%s' "${APP_STORE_CONNECT_ISSUER_ID:-$DEFAULT_ISSUER}" | tr -d '[:space:]')
[ -n "$KEY_ID" ] || KEY_ID="$DEFAULT_KEY_ID"
[ -n "$ISSUER" ] || ISSUER="$DEFAULT_ISSUER"
echo "Key ID: $KEY_ID"
echo "Issuer: $ISSUER"
mkdir -p "$HOME/private_keys"
KEY_PATH="$HOME/private_keys/AuthKey_${KEY_ID}.p8"
printf '%s\n' "$APP_STORE_CONNECT_KEY" > "$KEY_PATH"
grep -q "BEGIN PRIVATE KEY" "$KEY_PATH" || { echo "❌ APP_STORE_CONNECT_KEY لازم يكون محتوى ملف .p8 كامل مع سطري BEGIN و END"; exit 1; }
grep -q "END PRIVATE KEY" "$KEY_PATH" || { echo "❌ APP_STORE_CONNECT_KEY ناقص — سطر END PRIVATE KEY غير موجود"; exit 1; }
echo "✅ المفتاح سليم"
AUTH=(-allowProvisioningUpdates
      -authenticationKeyPath "$KEY_PATH"
      -authenticationKeyID "$KEY_ID"
      -authenticationKeyIssuerID "$ISSUER")

step "مشروع iOS"
if [ ! -d ios/Runner ]; then
  flutter create --org sa.almubarky --project-name qitaat --platforms=ios . > /tmp/flutter_create.log
  tail -3 /tmp/flutter_create.log
fi
rm -rf test

step "الحزم وتحليل الكود"
flutter pub get > /tmp/pub.log 2>&1 || { cat /tmp/pub.log; exit 1; }
flutter analyze --no-fatal-infos --no-fatal-warnings > /tmp/analyze.log 2>&1 || { cat /tmp/analyze.log; echo "❌ أخطاء في الكود"; exit 1; }
grep -E " error " /tmp/analyze.log || true
tail -1 /tmp/analyze.log

step "Info.plist (الاسم + نصوص الأذونات المطلوبة من Apple)"
P=ios/Runner/Info.plist
pset() {
  /usr/libexec/PlistBuddy -c "Delete :$1" "$P" 2>/dev/null || true
  /usr/libexec/PlistBuddy -c "Add :$1 $2 $3" "$P"
}
pset CFBundleDisplayName string "'قطعة سيارتك'"
pset CFBundleDevelopmentRegion string "ar"
pset ITSAppUsesNonExemptEncryption bool false
pset NSPhotoLibraryUsageDescription string "'يحتاج التطبيق الوصول للصور لإرفاق صور القطع في الطلبات والإعلانات'"
pset NSPhotoLibraryAddUsageDescription string "'يحتاج التطبيق حفظ صور القطع والفواتير في الصور'"
pset NSCameraUsageDescription string "'يحتاج التطبيق الكاميرا لتصوير القطع من 4 اتجاهات قبل الشحن ولإرفاقها في الطلبات'"
pset NSMicrophoneUsageDescription string "'يحتاج التطبيق الميكروفون عند تصوير مقطع للقطعة'"
for k in CFBundleDisplayName NSPhotoLibraryUsageDescription NSCameraUsageDescription; do
  echo "$k = $(/usr/libexec/PlistBuddy -c "Print :$k" "$P")"
done

step "معرّف التطبيق $BUNDLE_ID"
sed -i '' "s/PRODUCT_BUNDLE_IDENTIFIER = sa\.almubarky\.qitaat;/PRODUCT_BUNDLE_IDENTIFIER = ${BUNDLE_ID};/g" ios/Runner.xcodeproj/project.pbxproj
grep -m1 "PRODUCT_BUNDLE_IDENTIFIER" ios/Runner.xcodeproj/project.pbxproj

BUILD=$(( 100 + ${GITHUB_RUN_NUMBER:-1} ))
step "بناء Flutter (رقم البناء $BUILD)"
flutter build ios --release --no-codesign --build-number=$BUILD

step "الأرشفة (بدون توقيع — التوقيع وقت التصدير)"
xcodebuild -quiet \
  -workspace ios/Runner.xcworkspace \
  -scheme Runner \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath build/Runner.xcarchive \
  archive \
  DEVELOPMENT_TEAM="$TEAM_ID" \
  CODE_SIGN_STYLE=Automatic \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY=""

step "التوقيع للتوزيع والرفع إلى TestFlight"
cat > build/ExportOptions.plist <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key><string>app-store-connect</string>
  <key>destination</key><string>upload</string>
  <key>teamID</key><string>${TEAM_ID}</string>
  <key>signingStyle</key><string>automatic</string>
  <key>uploadSymbols</key><true/>
  <key>manageAppVersionAndBuildNumber</key><false/>
</dict>
</plist>
EOF
xcodebuild -exportArchive \
  -archivePath build/Runner.xcarchive \
  -exportOptionsPlist build/ExportOptions.plist \
  -exportPath build/export \
  "${AUTH[@]}"

step "✅ اكتمل — النسخة $BUILD مرفوعة إلى TestFlight (تظهر خلال ١٠–٢٠ دقيقة)"
