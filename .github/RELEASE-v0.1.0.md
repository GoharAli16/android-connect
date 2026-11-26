# Android Connect v0.1.0 — Wireless ADB & QR Pairing for macOS

The first open-source release of Android Connect: a native Mac menu bar app for Android wireless debugging without keeping Android Studio open.

## Included

- QR pairing and six-digit pairing-code fallback.
- Bonjour discovery alongside `adb mdns services`.
- Manual IP:port connection, USB/wireless device list and wireless disconnect.
- Optional start at login through macOS ServiceManagement.
- Bounded scrollable popover and Local Network / pairing-error guidance.
- Pairing secrets passed through stdin instead of process arguments.

## Install

Download **Android-Connect-v0.1.0-universal.zip**, extract, and move **Android Connect.app** to Applications. Install Google's Android SDK Platform-Tools separately. Requires macOS 13+, Android 11+ and the same Wi-Fi network. Universal arm64 / x86_64 binary.

**Ad-hoc signed; not Apple notarized.** macOS may require approval under Privacy & Security. Review or build the MIT-licensed source if preferred. `SHA256SUMS.txt` provides download integrity checks; it is not a notarization or independent authenticity guarantee.

## Validation and limits

Local universal compilation, self-tests and codesign verification completed. Previous development verified Pixel 8 Pro QR acceptance, Bonjour discovery and a wireless shell command after correcting Local Network permissions. A complete fresh QR-only pairing flow, Intel runtime execution and reboot-to-login acceptance remain unverified. Discovery refresh runs while the menu is open; background reconnection is not guaranteed.

[Setup and troubleshooting](https://goharali16.github.io/android-connect/) · [Source](https://github.com/GoharAli16/android-connect)
