#!/bin/bash

APP_NAME="Pomodoro"
BUNDLE_ID="com.example.pomodoro"
EXECUTABLE_NAME="Pomodoro"

echo "Building App with swiftc..."
swiftc Sources/Pomodoro/*.swift -o ${EXECUTABLE_NAME} -target arm64-apple-macosx15.0

echo "Creating App Bundle Structure..."
APP_DIR="${APP_NAME}.app"
CONTENTS_DIR="${APP_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

rm -rf "${APP_DIR}"
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

echo "Moving Executable and Resources..."
mv "${EXECUTABLE_NAME}" "${MACOS_DIR}/${EXECUTABLE_NAME}"
if [ -f "AppIcon.icns" ]; then
    cp AppIcon.icns "${RESOURCES_DIR}/AppIcon.icns"
fi

echo "Generating Info.plist..."
cat > "${CONTENTS_DIR}/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${EXECUTABLE_NAME}</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>15.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
EOF

echo "Applying Code Signature and App Sandbox..."
ENTITLEMENTS_PLIST=$(mktemp)
cat > "${ENTITLEMENTS_PLIST}" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!--
      Security Audit Note:
      This application is a simple Pomodoro timer that relies exclusively on
      standard SwiftUI UI components, local UserDefaults (AppStorage) for persistence,
      and AppKit for playing system sounds. It does not require network access,
      user-selected file access, or inter-process communication. Therefore, the
      default-deny App Sandbox with zero additional capability entitlements is
      both appropriate and secure for its core functionality.
    -->
    <key>com.apple.security.app-sandbox</key>
    <true/>
</dict>
</plist>
EOF

codesign --force --options runtime --entitlements "${ENTITLEMENTS_PLIST}" --sign - "${APP_DIR}"
rm "${ENTITLEMENTS_PLIST}"

echo "Done! Run open ${APP_DIR} to start the app."
