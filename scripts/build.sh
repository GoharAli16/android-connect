#!/bin/zsh
set -eu
cd "${0:A:h}/.."
APP="$PWD/dist/Android Connect.app"
mkdir -p "$APP/Contents/MacOS"
ARCHS=${ARCHS:-$(uname -m)}
mkdir -p dist/bin
for arch in $=ARCHS; do
  swiftc -O -swift-version 5 -target "$arch-apple-macosx13.0" Sources/main.swift -o "dist/bin/AndroidConnect-$arch"
done
if [[ "$ARCHS" == *" "* ]]; then
  lipo -create dist/bin/AndroidConnect-* -output "$APP/Contents/MacOS/AndroidConnect"
else
  cp "dist/bin/AndroidConnect-$ARCHS" "$APP/Contents/MacOS/AndroidConnect"
fi
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>AndroidConnect</string>
<key>CFBundleIdentifier</key><string>local.androidconnect.menubar</string>
<key>CFBundleName</key><string>Android Connect</string>
<key>CFBundleVersion</key><string>1</string>
<key>CFBundleShortVersionString</key><string>0.1.0</string>
<key>LSMinimumSystemVersion</key><string>13.0</string>
<key>LSUIElement</key><true/>
<key>NSBonjourServices</key><array><string>_adb-tls-pairing._tcp</string><string>_adb-tls-connect._tcp</string></array>
<key>NSLocalNetworkUsageDescription</key><string>Discover Android wireless debugging devices on your local network.</string>
</dict></plist>
PLIST
codesign --force --sign - "$APP"
"$APP/Contents/MacOS/AndroidConnect" --self-test
print "Built: $APP"
