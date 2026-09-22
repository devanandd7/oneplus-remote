enum RemoteKey {
  power,
  mute,
  dpadUp,
  dpadDown,
  dpadLeft,
  dpadRight,
  ok,
  back,
  home,
  volumeUp,
  volumeDown,
  assistant,
  netflix,
  menu,
  camera,
  primeVideo,
  youtube,
  settings,
  input,
}

class RemoteKeyHelper {
  /// Android TV Remote v2 (Protobuf RemoteKeyCode) integer codes
  static int getAndroidTvKeyCode(RemoteKey key) {
    switch (key) {
      case RemoteKey.power:
        return 26; // KEYCODE_POWER
      case RemoteKey.mute:
        return 164; // KEYCODE_VOLUME_MUTE
      case RemoteKey.dpadUp:
        return 19; // KEYCODE_DPAD_UP
      case RemoteKey.dpadDown:
        return 20; // KEYCODE_DPAD_DOWN
      case RemoteKey.dpadLeft:
        return 21; // KEYCODE_DPAD_LEFT
      case RemoteKey.dpadRight:
        return 22; // KEYCODE_DPAD_RIGHT
      case RemoteKey.ok:
        return 23; // KEYCODE_DPAD_CENTER
      case RemoteKey.back:
        return 4; // KEYCODE_BACK
      case RemoteKey.home:
        return 3; // KEYCODE_HOME
      case RemoteKey.volumeUp:
        return 24; // KEYCODE_VOLUME_UP
      case RemoteKey.volumeDown:
        return 25; // KEYCODE_VOLUME_DOWN
      case RemoteKey.assistant:
        return 84; // KEYCODE_SEARCH
      case RemoteKey.menu:
        return 82; // KEYCODE_MENU
      case RemoteKey.camera:
        return 27; // KEYCODE_CAMERA
      case RemoteKey.settings:
        return 176; // KEYCODE_SETTINGS
      case RemoteKey.input:
        return 178; // KEYCODE_TV_INPUT
      default:
        return 0; // KEYCODE_UNKNOWN
    }
  }

  /// App links for direct app launching over Android TV Remote v2
  static String? getDeepLink(RemoteKey key) {
    switch (key) {
      case RemoteKey.netflix:
        return 'https://www.netflix.com/title/';
      case RemoteKey.primeVideo:
        return 'https://app.primevideo.com/';
      case RemoteKey.youtube:
        return 'https://www.youtube.com';
      default:
        return null;
    }
  }

  /// Bluetooth HID key identifier mapped to native Kotlin BluetoothHidManager
  static String getHidKeyName(RemoteKey key) {
    switch (key) {
      case RemoteKey.power:
        return 'POWER';
      case RemoteKey.mute:
        return 'MUTE';
      case RemoteKey.dpadUp:
        return 'DPAD_UP';
      case RemoteKey.dpadDown:
        return 'DPAD_DOWN';
      case RemoteKey.dpadLeft:
        return 'DPAD_LEFT';
      case RemoteKey.dpadRight:
        return 'DPAD_RIGHT';
      case RemoteKey.ok:
        return 'OK';
      case RemoteKey.back:
        return 'BACK';
      case RemoteKey.home:
        return 'HOME';
      case RemoteKey.volumeUp:
        return 'VOLUME_UP';
      case RemoteKey.volumeDown:
        return 'VOLUME_DOWN';
      case RemoteKey.menu:
        return 'MENU';
      case RemoteKey.camera:
        return 'CAMERA';
      case RemoteKey.youtube:
        return 'YOUTUBE';
      case RemoteKey.settings:
        return 'SETTINGS';
      case RemoteKey.input:
        return 'INPUT';
      default:
        return '';
    }
  }
}
