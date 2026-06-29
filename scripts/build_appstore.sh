#!/bin/bash
# Run from any directory: bash scripts/build_appstore.sh
set -euo pipefail
trap 'echo "Build stopped at line $LINENO. See the error above." >&2' ERR
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
fail() { echo "$*" >&2; exit 1; }
[[ "$(uname -s)" == Darwin ]] || fail 'This build requires macOS and Xcode.'
for tool in flutter pod xcodebuild xcrun security; do
  command -v "$tool" >/dev/null || fail "Missing $tool. Install Flutter, Xcode and CocoaPods before building."
done
xcodebuild -version
xcrun --sdk iphoneos --show-sdk-version
flutter --version

# A provided team takes priority. Only auto-select when exactly one team exists.
TEAM="${APPLE_TEAM_ID:-}"
if [[ -z "$TEAM" ]]; then
  TEAMS="$(security find-identity -v -p codesigning | sed -nE 's/.*\(([A-Z0-9]{10})\)".*/\1/p' | sort -u)"
  COUNT="$(printf '%s\n' "$TEAMS" | sed '/^$/d' | wc -l | tr -d ' ')"
  [[ "$COUNT" == 1 ]] || fail 'Cannot select an Apple team. Sign into Xcode with your paid developer account, then run: APPLE_TEAM_ID=YOURTEAMID bash scripts/build_appstore.sh'
  TEAM="$TEAMS"
fi
[[ "$TEAM" =~ ^[A-Z0-9]{10}$ ]] || fail 'APPLE_TEAM_ID must contain exactly 10 uppercase letters/digits.'

# Use a separate output directory so a previous successful IPA stays intact.
STAMP="$(date -u +%Y%m%d-%H%M%S)-$$"
OUTPUT="$ROOT/build/appstore/$STAMP"
mkdir -p "$OUTPUT"
exec > >(tee "$OUTPUT/build.log") 2>&1
echo "Building com.sidarai.app for team $TEAM"

# Keep the reviewed Dart dependency versions. Never run pub upgrade here.
# Match the package source recorded in pubspec.lock on the originating machine.
export PUB_HOSTED_URL=https://pub.flutter-io.cn
# jsDelivr intermittently drops concurrent HTTP/2 CocoaPods requests. One
# request at a time is slower but avoids a failed dependency resolution.
export COCOAPODS_CDN_MAX_CONCURRENCY="${COCOAPODS_CDN_MAX_CONCURRENCY:-1}"
# Ensure removed Flutter assets, including previously embedded fonts, cannot
# survive from an older local build and be copied into the archive.
flutter clean
flutter pub get --enforce-lockfile
ARGS=(--release --config-only --no-codesign --no-pub)
if [[ -n "${BUILD_NUMBER:-}" ]]; then ARGS+=("--build-number=$BUILD_NUMBER"); fi
if [[ -n "${DART_DEFINES_FILE:-}" ]]; then
  [[ -f "$DART_DEFINES_FILE" ]] || fail 'DART_DEFINES_FILE does not exist.'
  ARGS+=("--dart-define-from-file=$DART_DEFINES_FILE")
fi
flutter build ios "${ARGS[@]}"
(cd ios && pod install --repo-update)
/usr/bin/plutil -lint ios/Runner/Info.plist

# Automatic signing uses the account already authenticated in Xcode.
xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner \
  -configuration Release -destination 'generic/platform=iOS' \
  -archivePath "$OUTPUT/Runner.xcarchive" \
  -allowProvisioningUpdates DEVELOPMENT_TEAM="$TEAM" CODE_SIGN_STYLE=Automatic archive

cp ios/ExportOptions.plist "$OUTPUT/ExportOptions.plist"
/usr/libexec/PlistBuddy -c "Add :teamID string $TEAM" "$OUTPUT/ExportOptions.plist"
xcodebuild -exportArchive -archivePath "$OUTPUT/Runner.xcarchive" \
  -exportPath "$OUTPUT/ipa" -exportOptionsPlist "$OUTPUT/ExportOptions.plist" \
  -allowProvisioningUpdates
shopt -s nullglob
IPAS=("$OUTPUT"/ipa/*.ipa)
[[ ${#IPAS[@]} -gt 0 ]] || fail 'Xcode did not export an IPA. Inspect build.log.'
echo "IPA ready: ${IPAS[0]}"
echo "Upload using Transporter. No upload was performed by this script."
