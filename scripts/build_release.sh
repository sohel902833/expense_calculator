#!/usr/bin/env bash
# Builds a signed, production-mode Android release (APK + App Bundle).
#
# What this does, in order:
#   1. Makes sure a real release-signing keystore exists (android/key.properties);
#      offers to create one interactively if not, since a "production" build
#      signed with the Flutter debug key isn't actually production-ready.
#   2. flutter pub get
#   3. Regenerates the Drift local-database code (dart run build_runner build)
#   4. flutter analyze (aborts the build on any error)
#   5. flutter build apk --release --dart-define=APP_MODE=PROD
#   6. flutter build appbundle --release --dart-define=APP_MODE=PROD
#
# APP_MODE=PROD is passed at build time (see lib/constants/app_mode.dart) --
# nothing in the source tree is edited, so there's nothing to forget to
# revert afterwards and no risk of a local debug build silently pointing at
# production Firestore data.
#
# Usage: scripts/build_release.sh

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

KEY_PROPERTIES="android/key.properties"

echo "==> Checking release signing config..."
if [ ! -f "$KEY_PROPERTIES" ]; then
  echo "No $KEY_PROPERTIES found -- this build would fall back to the Flutter"
  echo "debug key, which cannot be uploaded to the Play Store and isn't a real"
  echo "production build."
  echo

  if [ -t 0 ]; then
    read -r -p "Create a new upload keystore now? [y/N] " create_ks
  else
    create_ks="n"
  fi

  if [[ "$create_ks" =~ ^[Yy]$ ]]; then
    default_path="$HOME/expense-calculator-upload-keystore.jks"
    read -r -p "Keystore output path [$default_path]: " keystore_path
    keystore_path="${keystore_path:-$default_path}"

    if [ -f "$keystore_path" ]; then
      echo "Refusing to overwrite existing file: $keystore_path" >&2
      exit 1
    fi

    read -r -p "Key alias [upload]: " key_alias
    key_alias="${key_alias:-upload}"

    echo
    echo "keytool will now prompt you for the keystore password, your name/org"
    echo "details, and confirmation -- use a real password and keep it safe."
    echo
    keytool -genkey -v \
      -keystore "$keystore_path" \
      -keyalg RSA -keysize 2048 -validity 10000 \
      -alias "$key_alias"

    echo
    echo "Now re-enter the same passwords so they can be saved to $KEY_PROPERTIES"
    echo "(gitignored -- never commit this file)."
    read -r -s -p "Keystore password: " store_password
    echo
    read -r -s -p "Key password (press Enter to reuse the keystore password): " key_password
    echo
    key_password="${key_password:-$store_password}"

    cat > "$KEY_PROPERTIES" <<EOF
storePassword=$store_password
keyPassword=$key_password
keyAlias=$key_alias
storeFile=$keystore_path
EOF
    echo
    echo "Wrote $KEY_PROPERTIES."
    echo "IMPORTANT: back up $keystore_path somewhere safe *outside* this repo."
    echo "Losing it means you can never publish an update to this app under"
    echo "the same signing identity again."
    echo
  else
    echo
    echo "Aborting -- create $KEY_PROPERTIES yourself before running this script:"
    echo "  https://docs.flutter.dev/deployment/android#signing-the-app"
    exit 1
  fi
fi

echo "==> flutter pub get"
flutter pub get

echo "==> Regenerating Drift database code"
dart run build_runner build --delete-conflicting-outputs

echo "==> flutter analyze"
# `flutter analyze` exits non-zero on any warning, not just errors -- this
# project has a handful of pre-existing warnings (unused imports, dead code)
# that don't affect the build. Only abort the release on real errors.
set +e
analyze_output="$(flutter analyze 2>&1)"
set -e
echo "$analyze_output"
if echo "$analyze_output" | grep -qE '^\s*error •'; then
  echo
  echo "flutter analyze found errors above -- aborting release build."
  exit 1
fi

echo "==> Building release APK (APP_MODE=PROD)"
flutter build apk --release --dart-define=APP_MODE=PROD

echo "==> Building release App Bundle (APP_MODE=PROD) for Play Store"
flutter build appbundle --release --dart-define=APP_MODE=PROD

echo
echo "Done."
echo "APK: build/app/outputs/flutter-apk/app-release.apk"
echo "AAB: build/app/outputs/bundle/release/app-release.aab"
