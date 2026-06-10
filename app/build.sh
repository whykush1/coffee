#!/bin/bash

# Exit on error
set -e

APP_NAME="Coffee"
APP_BUNDLE="${APP_NAME}.app"
CONTENTS_DIR="${APP_BUNDLE}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

echo "Cleaning up old build..."
rm -rf "${APP_BUNDLE}"
rm -f "${APP_NAME}"

echo "Copying Frameworks..."
mkdir -p "${CONTENTS_DIR}/Frameworks"
cp -R ../Sparkle/Sparkle.framework "${CONTENTS_DIR}/Frameworks/"

echo "Compiling Swift files..."
swiftc -framework SwiftUI -framework IOKit -framework Foundation -framework ServiceManagement \
    -F ../Sparkle -framework Sparkle \
    -Xlinker -rpath -Xlinker @executable_path/../Frameworks \
    CoffeeApp.swift \
    ContentView.swift \
    SleepManager.swift \
    UpdaterManager.swift \
    -o "${APP_NAME}"

echo "Creating App Bundle structure..."
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

echo "Generating App Icon..."
mkdir -p Coffee.iconset
sips -z 16 16     "../Icons/Coffee Icon.png" --out Coffee.iconset/icon_16x16.png > /dev/null
sips -z 32 32     "../Icons/Coffee Icon.png" --out Coffee.iconset/icon_16x16@2x.png > /dev/null
sips -z 32 32     "../Icons/Coffee Icon.png" --out Coffee.iconset/icon_32x32.png > /dev/null
sips -z 64 64     "../Icons/Coffee Icon.png" --out Coffee.iconset/icon_32x32@2x.png > /dev/null
sips -z 128 128   "../Icons/Coffee Icon.png" --out Coffee.iconset/icon_128x128.png > /dev/null
sips -z 256 256   "../Icons/Coffee Icon.png" --out Coffee.iconset/icon_128x128@2x.png > /dev/null
sips -z 256 256   "../Icons/Coffee Icon.png" --out Coffee.iconset/icon_256x256.png > /dev/null
sips -z 512 512   "../Icons/Coffee Icon.png" --out Coffee.iconset/icon_256x256@2x.png > /dev/null
sips -z 512 512   "../Icons/Coffee Icon.png" --out Coffee.iconset/icon_512x512.png > /dev/null
sips -z 1.14 1.14 "../Icons/Coffee Icon.png" --out Coffee.iconset/icon_512x512@2x.png > /dev/null
iconutil -c icns Coffee.iconset
rm -R Coffee.iconset
cp "Coffee.icns" "${RESOURCES_DIR}/"
cp ../Icons/*.png "${RESOURCES_DIR}/"

echo "Moving executable..."
mv "${APP_NAME}" "${MACOS_DIR}/"

echo "Creating Info.plist..."
cat > "${CONTENTS_DIR}/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>com.kushhooda.Coffee</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.1</string>
    <key>CFBundleVersion</key>
    <string>1.1</string>
    <key>LSMinimumSystemVersion</key>
    <string>11.0</string>
    <key>CFBundleIconFile</key>
    <string>Coffee</string>
    <key>SUFeedURL</key>
    <string>https://whykush1.github.io/coffee/appcast.xml</string>
    <key>SUPublicEDKey</key>
    <string>aIvyx+0/GNhurGtEX6oHwmZQ0Ti6StFBAM3QaeZJFtU=</string>
    <key>SUEnableAutomaticChecks</key>
    <true/>
    <key>SUAllowsAutomaticUpdatesFromUnsignedUpdates</key>
    <true/>
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key>
        <true/>
    </dict>
</dict>
</plist>
EOF

echo "Signing App..."
codesign --force --deep -s - "Coffee.app"

echo "Build complete: ${APP_BUNDLE}"
