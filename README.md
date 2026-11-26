# Android Connect — Wireless ADB & QR Pairing for macOS

**Connect your Android phone to ADB over Wi-Fi from your Mac’s menu bar.** Scan a QR code, pair with a six-digit code, or connect by IP address—without opening Android Studio.

[Download](https://github.com/GoharAli16/android-connect/releases/latest) · [Setup guide](https://goharali16.github.io/android-connect/setup.html) · [Troubleshooting](https://goharali16.github.io/android-connect/troubleshooting.html) · [MIT license](LICENSE)

Android Connect is a small native Swift / SwiftUI app for Android developers who use terminal tools, Flutter, VS Code, scrcpy, or Android Studio. It uses your existing Android SDK Platform-Tools and the standard ADB server, so connected devices are available to other ADB tools.

## Features

- **Wireless ADB QR pairing:** scan with Android’s Wireless debugging scanner.
- **Pairing-code fallback:** enter the phone’s pairing IP, port and six-digit code.
- **Bonjour device discovery:** supplements `adb mdns services` when ADB misses a phone.
- **Connect by IP:** use the separate debugging endpoint after pairing.
- **Device list:** view USB and wireless devices; disconnect a wireless device.
- **Start at login:** register the installed app as a macOS login item.
- **Local diagnostics:** clearer guidance for “No route to host” and pairing protocol errors.
- **Native menu bar interface:** bounded, scrollable popover; no third-party Swift dependencies.

## Requirements

- macOS 13 Ventura or newer.
- Android 11 or newer with Developer options and Wireless debugging enabled.
- Mac and phone on the same Wi-Fi network with device-to-device traffic allowed.
- Google’s [Android SDK Platform-Tools](https://developer.android.com/tools/releases/platform-tools) installed separately. Android Studio itself is optional.

## Install

Download the universal Apple silicon / Intel ZIP from [Releases](https://github.com/GoharAli16/android-connect/releases/latest), unzip it, and move **Android Connect.app** to **Applications**.

The initial release is **ad-hoc signed, not Apple notarized**. macOS may require approval in System Settings → Privacy & Security before opening it. Review the source and build locally if preferred. ADB is not bundled.

ADB is detected at `~/Library/Android/sdk/platform-tools/adb`, `/opt/homebrew/bin/adb`, or `/usr/local/bin/adb`. Choose another executable with **ADB…**.

## Pair Android over Wi-Fi with a QR code

1. Open Android Connect and click its radio-wave menu bar icon.
2. On the phone, open **Settings → Developer options → Wireless debugging** and enable it.
3. Choose **Pair device with QR code** and scan the Mac app’s QR. Use this scanner, not the normal Camera or Wi-Fi scanner.
4. Keep the menu and phone scanner open while pairing finishes. The app discovers the matching pairing service and then attempts to connect to that phone’s debugging endpoint.
5. Confirm the device in the app or run `adb devices -l`. A USB cable is not required for this pairing flow.

QR credentials change after five minutes while the menu is open, after successful pairing, or when you choose **New QR**.

### Pair with a six-digit code

On Android, choose **Pair device with pairing code**. Expand **Pair with a code instead** in the Mac app and enter that dialog’s IP:port and code. If needed, connect using the separate IP:port on the main Wireless debugging screen. **Pairing and debugging ports differ.**

### Start automatically at login

After moving the app to `/Applications`, run:

```sh
"/Applications/Android Connect.app/Contents/MacOS/AndroidConnect" --enable-login
```

Check with `--login-status` (1 means enabled; 2 means approval required). Manage it in **System Settings → General → Login Items & Extensions**. It starts in the menu bar when you log in after restarting.

## Wireless ADB troubleshooting on Mac

**“No route to host”** can be caused by Local Network permission for the app that launched the shared ADB server, even when Android Connect itself has permission. Check **System Settings → Privacy & Security → Local Network** for Android Connect and the relevant Terminal, IDE, or development app. Other possible causes include VPN routing and Wi-Fi client isolation.

**“protocol fault (couldn’t read status message)”** does not establish that the QR password is wrong. The app reads new ADB server log entries when available to expose the underlying network failure. Keep the phone’s scanner open and use **New QR** to retry.

**Restart ADB** restarts the shared server and interrupts debugging sessions in other tools. Use it after checking permissions. For discovery failures and changing ports, see the [troubleshooting guide](docs/troubleshooting.md).

## Build from source

Install Xcode command-line tools, then:

```sh
git clone https://github.com/GoharAli16/android-connect.git
cd android-connect
./scripts/build.sh
open 'dist/Android Connect.app'
```

To build a universal binary:

```sh
ARCHS='arm64 x86_64' ./scripts/build.sh
```

The script compiles, ad-hoc signs, and runs parsing, address-validation and error-guidance checks. GitHub Actions repeats the universal build and signature verification.

```sh
'dist/Android Connect.app/Contents/MacOS/AndroidConnect' --diagnose-mdns
```

The diagnostic prints local device service names and IP addresses. Review and redact them before sharing.

## Privacy, behavior and limitations

No accounts, analytics, cloud relay or companion Android app. The app uses local Bonjour discovery and your existing ADB server and keys. QR secrets stay in memory and are passed to ADB through standard input, not command-line arguments. macOS stores the chosen ADB path and optional login registration; ADB manages its own keys and trusted devices. Pairing grants normal ADB debugging access; revoke this Mac in the phone’s Wireless debugging settings when needed.

Discovery refresh and automatic pairing run **while the popover is open**. This release does not promise background reconnection after Wi-Fi changes or device reboots. Existing ADB connections remain available when the popover closes. Quitting the app leaves the shared ADB server running.

During development, QR acceptance and Bonjour discovery were observed on a Pixel 8 Pro, and a wireless ADB shell command succeeded after the server host’s Local Network permission was enabled. A complete fresh QR-only pairing flow across devices, Intel runtime testing, and reboot-to-login acceptance have not been verified. This is an initial **v0.1.0** release.

## Contribute

Read [CONTRIBUTING.md](CONTRIBUTING.md), report reproducible bugs, or suggest focused improvements. Please include macOS, Android and ADB versions and redact device identifiers. See [SECURITY.md](SECURITY.md) for vulnerability reporting.

[Android’s official wireless ADB documentation](https://developer.android.com/tools/adb#wireless-android11-command-line) · [ADB Wi-Fi protocol](https://android.googlesource.com/platform/packages/modules/adb/+/refs/heads/main/docs/dev/adb_wifi.md)

## License

MIT © Gohar Ali. Independent project; not affiliated with or endorsed by Google or Apple.
