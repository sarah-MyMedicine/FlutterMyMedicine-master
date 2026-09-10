#!/usr/bin/env bash
set -euo pipefail

echo "🔹 Write Facebook Meta.xcconfig"
cat > ios/Flutter/Meta.xcconfig <<EOF
FACEBOOK_APP_ID = ${FACEBOOK_APP_ID:-}
FACEBOOK_CLIENT_TOKEN = ${FACEBOOK_CLIENT_TOKEN:-}
EOF

echo "🔹 Flutter hard clean"
flutter clean || true

echo "🔹 Remove iOS artifacts and caches"
rm -rf ios/Pods ios/.symlinks ios/Flutter/Flutter.framework ios/Flutter/Flutter.podspec ios/Podfile.lock
rm -rf ~/Library/Developer/Xcode/DerivedData
rm -rf ~/Library/Caches/CocoaPods
pod cache clean --all || true

echo "🔹 Restore Dart deps"
flutter pub get

echo "🔹 CocoaPods / Homebrew (non-fatal)"
# make brew safe + remove the broken tap
set +e
brew untap robotsandpencils/homebrew-made >/dev/null 2>&1 || true
brew tap --repair >/dev/null 2>&1 || true
HOMEBREW_NO_AUTO_UPDATE=1 brew update || true
HOMEBREW_NO_AUTO_UPDATE=1 brew install cocoapods || brew upgrade cocoapods || true
set -e

pod --version

echo "🔹 Fresh Pod install (with repo update)"
cd ios
pod repo update
pod deintegrate
pod install --repo-update
cd ..

echo "🔹 Sanity-check: privacy bundles"
grep -E "_privacy\.bundle" "ios/Pods/Target Support Files/Pods-Runner/Pods-Runner-resources.sh" \
  || echo "⚠️ No privacy bundles listed (will verify in build)"
