# OnePlus TV Remote — Flutter Mobile App

An authentic, modern Flutter remote control app for OnePlus Android TVs, modeled directly after the physical OnePlus TV remote ([image.png](file:///c:/Users/devan/Desktop/oneplus_remote/image.png)).

---

## ⚡ Dual-Engine Remote Architecture

This app supports **two independent connection engines**:

### 1. Wi-Fi Engine (Android TV Remote Protocol v2)
* **Protocol**: mDNS auto-discovery, TLS 1.2 on ports 6466 (pairing) and 6467 (control), Protocol Buffers.
* **Capabilities**:
  * Full D-pad navigation, Center OK, Back, Home, and Power control.
  * Direct App Shortcuts: Launch **Netflix**, **Prime Video**, and **YouTube** directly via deep link intents.
  * Easy on-screen pairing: Displays a 6-character PIN on the TV, which you enter into the app.
  * Volume rocker and status feedback.

### 2. Bluetooth HID Engine (`BluetoothHidDevice`)
* **Protocol**: Android native `BluetoothHidDevice` (API 28+) registering as an official wireless keyboard + consumer remote peripheral.
* **Capabilities**:
  * Works **100% offline** without Wi-Fi or router.
  * Direct pairing via **OnePlus TV Settings → Remotes & Accessories → Add Accessory**.
  * Instant, low-latency D-Pad (Up/Down/Left/Right), Enter, Back, Home, Volume +/-, and Mute.

---

## 📱 Visual Design & Aesthetics

The UI accurately replicates the OnePlus TV physical remote:
* **Matte chassis**: Deep dark OnePlus finish (`#17181A`) with soft bevels and realistic shadows.
* **Header**: Red power button with glow accent, microphone pinhole / status LED, and mute button.
* **D-Pad**: Large circular navigation wheel with tactile OK center.
* **System keys**: Authentic circular Back (`←`) and Home (`O`) buttons.
* **Volume Rocker**: Rounded horizontal bar with Volume `-`, Google Assistant center badge (with the four Google dots), and Volume `+`.
* **Quick Launch Pills**: Branded Netflix, MENU, Prime Video, and YouTube pills.
* **Live Protocol Terminal**: Collapsible drawer showing live TLS, Protobuf, and HID packet logs.

---

## 🚀 How to Run the App

1. Ensure you have the Flutter SDK installed and added to your `PATH`.
2. In the project root, fetch dependencies:
   ```bash
   flutter pub get
   ```
3. Connect your Android phone or launch an emulator and run:
   ```bash
   flutter run
   ```

---

## 📂 Project Structure

```
oneplus_remote/
├── lib/
│   ├── main.dart                             # App entry point, OnePlus dark theme
│   ├── models/
│   │   ├── remote_key.dart                   # Key codes & command definitions
│   │   ├── connection_mode.dart              # WiFi vs Bluetooth HID enum & state
│   │   └── tv_device.dart                    # Discovered TV model & metadata
│   ├── services/
│   │   ├── remote_controller.dart            # Unified controller orchestrating commands
│   │   ├── wifi_remote_service.dart          # Android TV Remote v2 protocol (TLS/Protobuf/mDNS)
│   │   ├── bluetooth_hid_service.dart        # PlatformChannel bridge to native Kotlin HID
│   │   └── haptic_service.dart               # Tactile haptic feedback manager
│   ├── ui/
│   │   ├── remote_screen.dart                # Main remote control screen & chassis
│   │   └── widgets/
│   │       ├── top_controls_widget.dart      # Power (red), Status LED, Mute, Mode switcher
│   │       ├── dpad_widget.dart              # Circular D-pad (Up, Down, Left, Right, OK)
│   │       ├── system_buttons_widget.dart    # Back and Home buttons
│   │       ├── volume_rocker_widget.dart     # Vol -, Google Assistant badge, Vol +
│   │       ├── app_shortcuts_widget.dart     # Netflix, Menu, Prime, YouTube pills
│   │       ├── pairing_dialog.dart           # PIN verification dialog for Wi-Fi pairing
│   │       └── discovery_sheet.dart          # TV scan & selection bottom sheet
│   └── utils/
│       └── constants.dart                    # Colors, styling tokens, metrics
├── android/
│   ├── app/
│   │   ├── build.gradle                      # minSdk 28 for Bluetooth HID Device API
│   │   └── src/main/
│   │       ├── AndroidManifest.xml           # BT & Wi-Fi permissions
│   │       └── kotlin/com/oneplus/remote/
│   │           ├── MainActivity.kt           # MethodChannel and EventChannel handlers
│   │           └── BluetoothHidManager.kt    # BluetoothHidDevice peripheral registration
│   └── build.gradle
└── test/
    └── remote_test.dart                      # Protocol & keycode mapping tests
```
