#!/bin/bash
# Builds build/gh-tracker.app. Notifications need a signed bundle, so the bare binary is not enough.
set -euo pipefail
cd "$(dirname "$0")/.."

config="${1:-release}"
app="build/gh-tracker.app"

swift build -c "$config" --product GHTracker
bin="$(swift build -c "$config" --show-bin-path)"

rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources/Fonts"
cp "$bin/GHTracker" "$app/Contents/MacOS/"
cp Support/Info.plist "$app/Contents/"
cp docs/design-system/fonts/*.woff2 "$app/Contents/Resources/Fonts/"
codesign --force --sign - "$app"

echo "$app"
