---
layout: default
title: Wireless ADB on macOS with QR Pairing
permalink: /setup.html
---
# Connect Android to ADB over Wi-Fi on Mac

[Android Connect](./) is a native menu bar app that handles QR pairing through your existing ADB installation. Android Studio does not need to be open.

## Before you pair

Use macOS 13+, Android 11+, and the same Wi-Fi network. Install [Google Platform-Tools](https://developer.android.com/tools/releases/platform-tools) and turn on Developer options on the phone.

## Install Android Connect

[Download the app](https://github.com/GoharAli16/android-connect/releases/latest), unzip it, and move it to Applications. The initial release is ad-hoc signed and not notarized; macOS may require approval in Privacy & Security. Source and build instructions are on [GitHub](https://github.com/GoharAli16/android-connect).

## QR pairing

Open the app from Applications, then click the radio-wave menu bar icon. On Android, go to Developer options → Wireless debugging → Pair device with QR code. Scan the app’s QR using that scanner and keep both views open until pairing completes.

The phone advertises a pairing endpoint through Bonjour. The app calls `adb pair`, then attempts to connect to the debugging endpoint. These endpoints have different ports.

## Pairing-code alternative

Choose Pair device with pairing code on the phone. Enter the displayed IP:port and six-digit code under Pair with a code instead. Use the debugging IP:port from the main Wireless debugging screen if a manual connection is needed.

## Confirm wireless access

Run `adb devices -l`. If USB is also connected, select the wireless serial explicitly when checking it with `adb -s <wireless-serial> shell getprop ro.product.model`. A USB device row alone does not prove Wi-Fi debugging works.

## Start at login

Run `"/Applications/Android Connect.app/Contents/MacOS/AndroidConnect" --enable-login`. Manage it in System Settings → General → Login Items & Extensions. It starts after login, not before a user session begins.

[Connection errors and fixes](troubleshooting.html) · [Source code](https://github.com/GoharAli16/android-connect)
