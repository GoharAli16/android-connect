---
layout: default
title: Fix Wireless ADB on Mac — No Route to Host and QR Pairing Errors
permalink: /troubleshooting.html
---
# Wireless ADB on macOS: connection and QR pairing troubleshooting

[Android Connect](./) uses your existing ADB server. Check network reachability, Bonjour discovery and pairing separately; an error shown during a QR scan does not necessarily mean the password is wrong.

## ADB says “No route to host” on Mac

Check System Settings → Privacy & Security → Local Network. Enable access for Android Connect and the application that launched the shared ADB server, such as Terminal or your IDE. The server may have started before Android Connect opened.

`adb server-status` reports its executable and log path on supported Platform-Tools versions. Inspect recent failures locally and redact identifiers before sharing logs. Also check same-network connectivity, VPN routing and Wi-Fi client isolation; Local Network permission is one possible cause, not the only cause.

In this project's Pixel 8 Pro development session, Bonjour found the phone while TCP connections failed. Enabling Local Network access for the development app hosting ADB allowed a wireless connection and a successful device shell command.

## “protocol fault (couldn't read status message): Undefined error: 0”

This can hide the underlying pairing failure. Android Connect checks new ADB server log lines for a matching “No route to host” error. If logs are unavailable, the cause remains unknown. Keep Android's QR scanner open, check reachability, generate a New QR, and retry. Do not assume that resetting phone permissions or changing a Wi-Fi password will fix it.

## Phone says the QR password is incorrect

Use Developer options → Wireless debugging → Pair device with QR code, rather than the Camera or ordinary Wi-Fi scanner. Generate a new QR and keep the Mac menu open. If the error persists, try pairing with the six-digit code. A successful QR decode, completed pairing and connected device are separate stages.

## `adb mdns services` is empty

Android Connect also uses macOS Bonjour for `_adb-tls-pairing._tcp` and `_adb-tls-connect._tcp`. If both methods fail, verify Wireless debugging is enabled and multicast is allowed between the devices. Some guest or corporate networks isolate clients.

## Paired, but the phone is not connected

Enter the IP:port from the main Wireless debugging screen under Connect by IP address. The pairing dialog's port is not the debugging port. Ports can change when Wireless debugging restarts.

## Should I restart ADB?

After checking permissions, the app's Restart ADB button can restart the shared server. It disconnects sessions used by other tools. It does not bypass network restrictions. Keep the app open and scan the fresh QR afterward.

## Does Android Connect reconnect in the background?

This release refreshes discovery and handles pairing while the popover is open. It does not promise automatic background reconnection after every network or phone restart. Trusted-device reconnection may also be provided by ADB itself.

[Setup guide](setup.html) · [Report a bug](https://github.com/GoharAli16/android-connect/issues) · [Official ADB guide](https://developer.android.com/tools/adb)
