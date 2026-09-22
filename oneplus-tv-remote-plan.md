# OnePlus TV Bluetooth Remote — Flutter App (Updated Plan)

Phone ko Android's **Bluetooth HID Device profile** se ek genuine wireless remote/keyboard banaya jayega, jise OnePlus TV (Android TV) bina kisi extra TV-side app ke pehchan legi.

**Research se confirm hua:** `BluetoothHidDevice.registerApp()` sirf `BLUETOOTH_CONNECT` runtime permission maangta hai (`BLUETOOTH_PRIVILEGED` nahi) — matlab third-party app se yeh legally aur technically possible hai, API 28 (Android 9) se. Koi ready Flutter plugin is kaam ke liye maujood nahi, isliye native Kotlin + MethodChannel bridge hi sahi rasta hai.

---

## 1. System Architecture

```mermaid
flowchart TB
    subgraph Flutter["FLUTTER APP (Dart UI)"]
        UI["D-Pad, OK, Back, Home,\nVolume +/-, Mute, Assistant"]
        Status["Connection status + haptics"]
    end

    subgraph Bridge["Platform Channel Bridge"]
        MC["MethodChannel\n'oneplus_remote/hid'\nsendKey(keyName)"]
        EC["EventChannel\nconnection state stream"]
    end

    subgraph Native["NATIVE ANDROID LAYER (Kotlin)"]
        HID["BluetoothHidDevice\nregisterApp()"]
        RD["HID Report Descriptor\n(Keyboard + Consumer Control)"]
        SVC["Foreground Service\n(battery-exemption safe)"]
    end

    TV["ONEPLUS TV (Android TV)\nnative BT input listener"]

    UI --> MC --> HID
    HID --> RD
    HID --> SVC
    EC --> Status
    HID -->|Bluetooth HID protocol| TV
    TV -->|connection state| EC
```

---

## 2. Pairing & Wake Flow

```mermaid
sequenceDiagram
    participant U as User
    participant PR as Physical Remote
    participant TV as OnePlus TV
    participant App as Flutter App
    participant HID as Kotlin HID Service

    U->>PR: Power ON (deep sleep se wake)
    Note over TV: BT HID cannot reliably wake\na fully powered-off TV — physical\nremote is mandatory for this step
    U->>TV: Settings → Remotes & Accessories → Add Accessory
    U->>App: Open app, tap Connect
    App->>HID: registerApp(SDP settings)
    HID->>TV: Advertise as HID device
    TV->>HID: Bond + Connect (one-time pairing)
    HID-->>App: onConnectionStateChanged(CONNECTED)
    App-->>U: Status = Connected (green indicator)
```

---

## 3. Key Press Flow

```mermaid
sequenceDiagram
    participant U as User
    participant UI as Flutter UI
    participant MC as MethodChannel
    participant HID as BluetoothHidDevice
    participant TV as OnePlus TV

    U->>UI: Tap D-Pad / Back / Home / Volume
    UI->>MC: invokeMethod('sendKey', keyName)
    MC->>HID: sendReport(KEY_DOWN)
    HID->>TV: HID input report (key down)
    Note over HID: ~50ms delay
    MC->>HID: sendReport(KEY_UP)
    HID->>TV: HID input report (key up)
    TV-->>U: Navigation action executes
    UI-->>U: Haptic feedback
```

---

## 4. Development Phases

```mermaid
gantt
    dateFormat  X
    axisFormat %d
    title MVP Timeline (in days)
    section Phase 1
    Native HID setup (Kotlin)        :p1, 0, 2d
    section Phase 2
    Platform Channel + key codes     :p2, after p1, 1d
    section Phase 3
    Flutter Remote UI + haptics      :p3, after p2, 1d
    section Phase 4
    Pairing & TV testing             :p4, after p3, 1d
```

| Phase | Kaam | Time |
|---|---|---|
| 1 | Bluetooth permissions, `BluetoothHidDevice` registration, HID Report Descriptor (D-pad, Back, Home, Volume, Media keys) | 1–2 din |
| 2 | `MethodChannel` (sendKey), `EventChannel` (connection state) | 1 din |
| 3 | OnePlus-style dark UI: D-pad, Back, Home, Volume, Mute, haptics | 1 din |
| 4 | Real TV pairing + bug fixing | 1 din |
| **Total** | **Working MVP** | **~3–5 din** |

---

## 5. Updated Risk Notes (naye findings)

| Risk | Detail | Mitigation |
|---|---|---|
| **OEM battery kill** | OxygenOS background service ko aggressively kill karta hai | HID service ko foreground service banao + battery-optimization exemption request karo (Phase 1 me hi) |
| **Assistant / mic button** | Physical remote ke center mic button (image me dikh raha) ke liye simple keyboard keycode kaam nahi karega — special HID usage code chahiye jo har TV firmware support nahi karta | Phase 4 me separately test karo; fallback: is button ko skip karo ya baad me add karo |
| **No Flutter plugin exists** | pub.dev pe koi ready package nahi mila jo Android ko HID *peripheral* banaye | Native Kotlin + MethodChannel bridge confirmed as the only route |
| **Deep-sleep wake** | BT HID se poori tarah OFF TV wake nahi hoti | Physical remote se power-on — plan me already correct |

---

## 6. Key Mapping Reference

| Remote Button | HID Usage |
|---|---|
| D-Pad Up/Down/Left/Right | Keyboard Arrow Keys |
| OK / Center | Keyboard Enter |
| Back | Keyboard Escape / AC_BACK (Consumer) |
| Home | AC_HOME (Consumer Control) |
| Volume +/- | VOLUME_INCREMENT / VOLUME_DECREMENT |
| Mute | Consumer Mute |
| Assistant (mic) | ⚠️ Needs extra research per-TV — not standard keyboard usage |
| Netflix / Prime / YouTube app buttons | Not achievable via plain HID keys — would need TV-specific deep links (out of scope for HID-only approach) |

---

**Next step:** Phase 1 se start karein — Kotlin `BluetoothHidDevice` registration + Report Descriptor code likhna shuru karein?
