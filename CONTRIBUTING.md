# Contributing to Android Connect

Open an issue describing the problem and expected behavior before large changes. Small focused fixes are welcome.

Run `./scripts/build.sh` on macOS with Xcode command-line tools. Include the result and any relevant phone test: USB detection, QR acceptance, completed pairing, and wireless shell access are different checks.

For UI changes, check the popover on a small display and with all disclosure sections expanded. Avoid including active QR credentials in screenshots. Never commit ADB keys, device logs, personal paths, or device identifiers.

Changes should preserve existing Android Studio and CLI behavior. Restarting the shared ADB server interrupts other tools; do not do so silently.
