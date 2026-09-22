import 'package:flutter_test/flutter_test.dart';
import 'package:oneplus_remote/models/remote_key.dart';
import 'package:oneplus_remote/models/tv_device.dart';
import 'package:oneplus_remote/models/macro_button.dart';

void main() {
  group('RemoteKey Mappings', () {
    test('Android TV Remote v2 keycodes are accurate', () {
      expect(RemoteKeyHelper.getAndroidTvKeyCode(RemoteKey.power), 26);
      expect(RemoteKeyHelper.getAndroidTvKeyCode(RemoteKey.dpadUp), 19);
      expect(RemoteKeyHelper.getAndroidTvKeyCode(RemoteKey.dpadDown), 20);
      expect(RemoteKeyHelper.getAndroidTvKeyCode(RemoteKey.dpadLeft), 21);
      expect(RemoteKeyHelper.getAndroidTvKeyCode(RemoteKey.dpadRight), 22);
      expect(RemoteKeyHelper.getAndroidTvKeyCode(RemoteKey.ok), 23);
      expect(RemoteKeyHelper.getAndroidTvKeyCode(RemoteKey.back), 4);
      expect(RemoteKeyHelper.getAndroidTvKeyCode(RemoteKey.home), 3);
      expect(RemoteKeyHelper.getAndroidTvKeyCode(RemoteKey.volumeUp), 24);
      expect(RemoteKeyHelper.getAndroidTvKeyCode(RemoteKey.volumeDown), 25);
      expect(RemoteKeyHelper.getAndroidTvKeyCode(RemoteKey.mute), 164);
      expect(RemoteKeyHelper.getAndroidTvKeyCode(RemoteKey.camera), 27);
      expect(RemoteKeyHelper.getAndroidTvKeyCode(RemoteKey.settings), 176);
    });

    test('App shortcut deep links are correct', () {
      expect(RemoteKeyHelper.getDeepLink(RemoteKey.netflix), 'https://www.netflix.com/title/');
      expect(RemoteKeyHelper.getDeepLink(RemoteKey.primeVideo), 'https://app.primevideo.com/');
      expect(RemoteKeyHelper.getDeepLink(RemoteKey.youtube), 'https://www.youtube.com');
      expect(RemoteKeyHelper.getDeepLink(RemoteKey.camera), isNull);
      expect(RemoteKeyHelper.getDeepLink(RemoteKey.power), isNull);
    });

    test('Bluetooth HID key names map accurately', () {
      expect(RemoteKeyHelper.getHidKeyName(RemoteKey.dpadUp), 'DPAD_UP');
      expect(RemoteKeyHelper.getHidKeyName(RemoteKey.ok), 'OK');
      expect(RemoteKeyHelper.getHidKeyName(RemoteKey.volumeUp), 'VOLUME_UP');
      expect(RemoteKeyHelper.getHidKeyName(RemoteKey.power), 'POWER');
      expect(RemoteKeyHelper.getHidKeyName(RemoteKey.camera), 'CAMERA');
      expect(RemoteKeyHelper.getHidKeyName(RemoteKey.youtube), 'YOUTUBE');
      expect(RemoteKeyHelper.getHidKeyName(RemoteKey.settings), 'SETTINGS');
    });
  });

  group('TvDevice Model', () {
    test('TvDevice serialization works', () {
      final tv = TvDevice(
        id: '192.168.1.50',
        name: 'Living Room OnePlus TV',
        ipAddress: '192.168.1.50',
        port: 6467,
        isPaired: true,
      );

      final json = tv.toJson();
      final reconstructed = TvDevice.fromJson(json);

      expect(reconstructed.id, tv.id);
      expect(reconstructed.name, tv.name);
      expect(reconstructed.ipAddress, tv.ipAddress);
      expect(reconstructed.isPaired, true);
    });
  });

  group('MacroButton Model', () {
    test('MacroButton serialization and deserialization preserves steps', () {
      final macro = MacroButton(
        id: 'macro_test_1',
        title: 'TV Settings Shortcut',
        iconCodePoint: 0xe57f,
        colorValue: 0xFF2196F3,
        steps: [
          const MacroStep(key: RemoteKey.home, delayMs: 400),
          const MacroStep(key: RemoteKey.dpadUp, delayMs: 200),
          const MacroStep(key: RemoteKey.dpadRight, delayMs: 200),
          const MacroStep(key: RemoteKey.ok, delayMs: 200),
        ],
      );

      final json = macro.toJson();
      final restored = MacroButton.fromJson(json);

      expect(restored.id, 'macro_test_1');
      expect(restored.title, 'TV Settings Shortcut');
      expect(restored.steps.length, 4);
      expect(restored.steps[0].key, RemoteKey.home);
      expect(restored.steps[3].key, RemoteKey.ok);
    });
  });
}
