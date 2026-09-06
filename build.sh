#!/bin/bash

cd "$(dirname "$0")"
export PATH="$HOME/.local/bin:$PATH"

echo "Building AxisLock..."
swift build || exit 1

echo "Creating application..."
rm -rf "output"
mkdir -p "output/AxisLock.app/Contents/MacOS"
mkdir -p "output/AxisLock.app/Contents/Resources"

cp "$(swift build --show-bin-path)/AxisLock" "output/AxisLock.app/Contents/MacOS/AxisLock"
cp "AxisLock.icns" "output/AxisLock.app/Contents/Resources/AxisLock.icns"
cp -R "$(swift build --show-bin-path)/AxisLock_AxisLock.bundle" "output/AxisLock.app/Contents/Resources/AxisLock_AxisLock.bundle"
cp "Info.plist" "output/AxisLock.app/Contents/Info.plist"

echo "Signing application..."
codesign --force --deep --sign - "output/AxisLock.app" || exit 1

echo "Creating DMG..."
rm -f "output/AxisLock.dmg"

cat > "output/dmg_settings.py" <<EOF

# DMG contents
files = [
    "output/AxisLock.app",
    "README_en.md",
    "README_cs.md",
]

symlinks = {
    "Applications": "/Applications",
}

# DMG window
window_rect = ((300, 300), (750, 300))

# Icons
icon_size = 96

icon_locations = {
    "README_en.md": (0, 105),
    "README_cs.md": (150, 105),
    "AxisLock.app": (350, 105),
    "Applications": (500, 105),
}

EOF

dmgbuild \
    -s "output/dmg_settings.py" \
    "AxisLock" \
    "output/AxisLock.dmg" || exit 1

rm -f "output/dmg_settings.py"

echo ""
echo "Build completed successfully."
echo "Application: output/AxisLock.app"
echo "DMG: output/AxisLock.dmg"