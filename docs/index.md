---
layout: default
title: Android Connect — Wireless ADB & QR Pairing for macOS
---
# Wireless Android debugging from your Mac menu bar

**Android Connect** is a free, MIT-licensed macOS app for connecting Android devices to ADB over Wi-Fi. Pair with a QR code, use a six-digit pairing code, or connect by IP—without opening Android Studio.

[Download Android Connect](https://github.com/GoharAli16/android-connect/releases/latest) · [View source on GitHub](https://github.com/GoharAli16/android-connect)

## App screenshots

![Android Connect wireless debugging popover with the surrounding desktop background removed](images/android-connect-panel-transparent.png)

*User-provided screenshot edited with AI to remove the surrounding desktop background. The QR is illustrative, not for live pairing. The Local Network error shown is explained in the [troubleshooting guide](troubleshooting.html).*

![Android Connect pairing panel showing code fallback, device list and connection controls](images/android-connect-pairing-panel.png)

*Actual user-provided development capture. The original crops the QR area; popover sizing was subsequently fixed. [See the historical pairing-error screenshot and explanation](troubleshooting.html#protocol-fault-couldnt-read-status-message-undefined-error-0).*

## Scan. Pair. Debug.

Open Android Connect, then scan its QR from **Developer options → Wireless debugging → Pair device with QR code** on your phone. Keep the menu open as the app discovers and pairs the phone and attempts its debugging connection.

Use the resulting ADB connection with your terminal, Flutter, VS Code, Android Studio, or other tools that use the same ADB server.

## A small native Mac app

- QR pairing and six-digit code fallback for Android 11+.
- Bonjour discovery alongside ADB's own service discovery.
- USB and wireless device list with wireless disconnect controls.
- Manual IP connection and local pairing-error guidance.
- Optional startup at login, managed through macOS Login Items.
- Swift / SwiftUI, with no third-party Swift dependencies.

## Requirements and download

Requires **macOS 13+**, **Android 11+**, Google's separately installed **Android SDK Platform-Tools**, and a shared Wi-Fi network. The universal release supports Apple silicon and Intel builds. Intel runtime acceptance remains unverified.

The initial v0.1.0 release is **ad-hoc signed and not Apple notarized**. Review the source or build it locally if preferred. macOS may require approval in Privacy & Security.

[Read the setup guide](setup.html)

## ADB “No route to host” or QR pairing errors?

Local Network access can depend on the app that launched the shared ADB server, not just the menu bar app. Our guide explains how to inspect that, distinguish the pairing port from the debugging port, and check discovery before resetting anything.

[Read the wireless ADB troubleshooting guide](troubleshooting.html)

## Does it need a USB cable or Android Studio?

Android 11+ QR pairing does not require an initial USB connection. Android Connect needs ADB Platform-Tools, but Android Studio itself does not need to be open.

## Does it run at login?

Yes. Register the installed app as a login item using the command in the setup guide. It starts quietly in the menu bar after login. This release does not promise continuous background reconnection; discovery refresh runs while the menu is open.

## Open source, local connections

No account, analytics or cloud relay. Android Connect uses local discovery and your existing ADB keys. Pairing grants your Mac debugging access; manage and revoke paired computers from Android's Wireless debugging settings.

[MIT license](https://github.com/GoharAli16/android-connect/blob/main/LICENSE) · [Contribute](https://github.com/GoharAli16/android-connect/blob/main/CONTRIBUTING.md) · [Report an issue](https://github.com/GoharAli16/android-connect/issues)

Independent project by Gohar Ali. Not affiliated with Google or Apple.

<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "SoftwareApplication",
  "name": "Android Connect",
  "url": "https://goharali16.github.io/android-connect/",
  "description": "Open-source macOS menu bar app for wireless ADB and Android QR pairing without opening Android Studio.",
  "operatingSystem": "macOS 13 or newer",
  "applicationCategory": "DeveloperApplication",
  "softwareVersion": "0.1.0",
  "license": "https://github.com/GoharAli16/android-connect/blob/main/LICENSE",
  "downloadUrl": "https://github.com/GoharAli16/android-connect/releases/latest",
  "offers": {"@type": "Offer", "price": "0", "priceCurrency": "USD"},
  "author": {"@type": "Person", "name": "Gohar Ali", "url": "https://github.com/GoharAli16"}
}
</script>
