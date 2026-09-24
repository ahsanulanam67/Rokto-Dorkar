#!/usr/bin/env bash
set -euo pipefail

if ! command -v flutter >/dev/null 2>&1; then
  git clone --depth 1 --branch stable https://github.com/flutter/flutter.git "$PWD/.flutter-sdk"
  export PATH="$PWD/.flutter-sdk/bin:$PATH"
fi

flutter config --enable-web
flutter pub get
flutter build web --release --dart-define="API_BASE_URL=${API_BASE_URL:?Set API_BASE_URL in Vercel}"
