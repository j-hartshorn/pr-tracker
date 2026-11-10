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

iconset="$(mktemp -d)/AppIcon.iconset"
mkdir "$iconset"
for size in 16 32 128 256 512; do
    sips -s format png -z "$size" "$size" Support/AppIcon.svg --out "$iconset/icon_${size}x${size}.png" >/dev/null
    sips -s format png -z "$((size * 2))" "$((size * 2))" Support/AppIcon.svg --out "$iconset/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns "$iconset" -o "$app/Contents/Resources/AppIcon.icns"
codesign --force --sign - "$app"

echo "$app"
