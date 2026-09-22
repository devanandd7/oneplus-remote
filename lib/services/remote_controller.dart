import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/remote_key.dart';
import '../models/connection_mode.dart';
import '../models/tv_device.dart';
import '../models/macro_button.dart';
import 'wifi_remote_service.dart';
import 'bluetooth_hid_service.dart';
import 'haptic_service.dart';
import 'tv_companion_client.dart';
import 'local_apk_server_service.dart';

class RemoteController extends ChangeNotifier {
  final WifiRemoteService _wifiService = WifiRemoteService();
  final BluetoothHidService _btService = BluetoothHidService();
  final TvCompanionClient _companionClient = TvCompanionClient();
  final LocalApkServerService _localServer = LocalApkServerService();

  TvCompanionClient get companionClient => _companionClient;
  bool get isCompanionConnected => _companionClient.isConnected;
  TvScreenState get tvScreenState => _companionClient.currentState;
  LocalApkServerService get localServer => _localServer;

  RemoteEngineMode _currentMode = RemoteEngineMode.bluetooth;
  RemoteEngineMode get currentMode => _currentMode;

  ConnectionStatus _status = ConnectionStatus.disconnected;
  ConnectionStatus get status => _status;

  TvDevice? _selectedTv;
  TvDevice? get selectedTv => _selectedTv;

  final List<TvDevice> _discoveredDevices = [];
  List<TvDevice> get discoveredDevices => List.unmodifiable(_discoveredDevices);

  final List<String> _recentLogs = [];
  List<String> get recentLogs => List.unmodifiable(_recentLogs);

  // Custom Macro Recording & Playback State
  List<MacroButton> _customMacros = [];
  List<MacroButton> get customMacros => List.unmodifiable(_customMacros);

  bool _isRecordingMacro = false;
  bool get isRecordingMacro => _isRecordingMacro;

  final List<RemoteKey> _recordedSteps = [];
  List<RemoteKey> get recordedSteps => List.unmodifiable(_recordedSteps);

  bool _isPlayingMacro = false;
  bool get isPlayingMacro => _isPlayingMacro;

  String? _playingMacroTitle;
  String? get playingMacroTitle => _playingMacroTitle;

  int _playingStepIndex = 0;
  int get playingStepIndex => _playingStepIndex;

  String _playbackStatusMessage = '';
  String get playbackStatusMessage => _playbackStatusMessage;

  StreamSubscription? _wifiStatusSub;
  StreamSubscription? _btStatusSub;
  StreamSubscription? _wifiLogSub;
  StreamSubscription? _btLogSub;

  RemoteController() {
    _initListeners();
    _btService.initialize();
    loadSavedMacros();
    _localServer.start();
  }

  void _initListeners() {
    _wifiStatusSub = _wifiService.statusStream.listen((newStatus) {
      if (_currentMode == RemoteEngineMode.wifi) {
        _status = newStatus;
        notifyListeners();
      }
    });

    _btStatusSub = _btService.statusStream.listen((newStatus) {
      if (_currentMode == RemoteEngineMode.bluetooth) {
        _status = newStatus;
        notifyListeners();
      }
    });

    _wifiLogSub = _wifiService.logStream.listen((log) {
      _addLog('[Wi-Fi] $log');
    });

    _btLogSub = _btService.logStream.listen((log) {
      _addLog('[BT] $log');
    });

    _companionClient.addListener(notifyListeners);
    _companionClient.onLog.listen((log) {
      _addLog('[Companion] $log');
    });

    _localServer.addListener(notifyListeners);
    _localServer.onLog.listen((log) {
      _addLog('[ApkServer] $log');
    });
  }

  void _addLog(String log) {
    _recentLogs.insert(0, log);
    if (_recentLogs.length > 50) {
      _recentLogs.removeLast();
    }
    notifyListeners();
  }

  String get connectedTitle {
    if (_status != ConnectionStatus.connected) {
      return _status.displayName;
    }
    if (_currentMode == RemoteEngineMode.wifi) {
      return _selectedTv?.name ?? 'OnePlus TV (Wi-Fi)';
    } else {
      return _btService.connectedDeviceName ?? 'OnePlus TV (Bluetooth)';
    }
  }

  String? get connectedDeviceAddress => _btService.connectedDeviceAddress;

  Future<void> switchMode(RemoteEngineMode mode) async {
    if (_currentMode == mode) return;
    _currentMode = mode;
    _status = ConnectionStatus.disconnected;
    _addLog('Switched connection mode to ${mode.name.toUpperCase()}');
    notifyListeners();

    if (mode == RemoteEngineMode.bluetooth) {
      await _btService.initialize();
    }
  }

  Future<void> sendKey(RemoteKey key) async {
    // Fire tactile haptic feedback immediately
    if (key == RemoteKey.power) {
      HapticService.powerClick();
    } else {
      HapticService.buttonClick();
    }

    // If recording a macro, capture key sequence
    if (_isRecordingMacro) {
      _recordedSteps.add(key);
      _addLog('[Macro] Captured step: ${key.name.toUpperCase()}');
      notifyListeners();
    }

    if (_currentMode == RemoteEngineMode.wifi) {
      await _wifiService.sendKey(key);
    } else {
      await _btService.sendKey(key);
    }
  }

  Future<void> sendText(String text) async {
    HapticService.buttonClick();
    _addLog('[Keyboard] Sending: "$text"');
    await _btService.sendText(text);
  }

  Future<void> sendBackspace() async {
    HapticService.navigationClick();
    await _btService.sendBackspace();
  }

  Future<void> sendSpace() async {
    HapticService.navigationClick();
    await _btService.sendSpace();
  }

  Future<void> sendEnter() async {
    HapticService.buttonClick();
    await _btService.sendEnter();
  }

  // --- Macro Recording & Playback Management ---

  Future<void> loadSavedMacros() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('custom_remote_macros');
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(raw);
        _customMacros = decoded.map((item) => MacroButton.fromJson(item)).toList();
      } else {
        // Provide a default "TV Settings" shortcut
        _customMacros = [
          MacroButton(
            id: 'default_settings',
            title: 'TV Settings',
            iconCodePoint: 0xe57f, // Icons.settings
            colorValue: 0xFF2196F3, // Material Blue
            steps: [
              const MacroStep(key: RemoteKey.settings, delayMs: 1000),
            ],
          ),
        ];
        await _persistMacros();
      }
      notifyListeners();
    } catch (e) {
      _addLog('[Macro] Error loading saved macros: $e');
    }
  }

  Future<void> _persistMacros() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode(_customMacros.map((m) => m.toJson()).toList());
      await prefs.setString('custom_remote_macros', raw);
    } catch (e) {
      _addLog('[Macro] Error saving macros: $e');
    }
  }

  Future<void> startMacroRecording() async {
    _isRecordingMacro = true;
    _recordedSteps.clear();
    _addLog('[Macro] 🔴 Recording started. Setting TV to Home anchor (please wait ~3s)...');
    notifyListeners();

    // Reset TV to Home anchor: 1st Home exits any current app, 2nd Home sets focus to Top-Left
    if (_currentMode == RemoteEngineMode.wifi) {
      await _wifiService.sendKey(RemoteKey.home);
      await Future.delayed(const Duration(milliseconds: 1500));
      await _wifiService.sendKey(RemoteKey.home);
    } else {
      await _btService.sendKey(RemoteKey.home);
      await Future.delayed(const Duration(milliseconds: 1500));
      await _btService.sendKey(RemoteKey.home);
    }
    _addLog('[Macro] 🎯 TV ready at Home anchor. Press buttons on remote to record your shortcut.');
    notifyListeners();
  }

  void cancelMacroRecording() {
    _isRecordingMacro = false;
    _recordedSteps.clear();
    _addLog('[Macro] Recording cancelled.');
    notifyListeners();
  }

  Future<void> saveMacro({
    required String title,
    required int iconCodePoint,
    required int colorValue,
    int stepDelayMs = 1000,
  }) async {
    if (_recordedSteps.isEmpty) {
      cancelMacroRecording();
      return;
    }

    final newMacro = MacroButton(
      id: 'macro_${DateTime.now().millisecondsSinceEpoch}',
      title: title.trim().isEmpty ? 'Custom Shortcut' : title.trim(),
      iconCodePoint: iconCodePoint,
      colorValue: colorValue,
      steps: _recordedSteps
          .map((k) => MacroStep(key: k, delayMs: stepDelayMs))
          .toList(),
    );

    _customMacros.add(newMacro);
    await _persistMacros();
    _isRecordingMacro = false;
    _recordedSteps.clear();
    _addLog('[Macro] ✅ Saved custom button "${newMacro.title}" (${newMacro.steps.length} steps).');
    notifyListeners();
  }

  Future<void> deleteMacro(String id) async {
    _customMacros.removeWhere((m) => m.id == id);
    await _persistMacros();
    _addLog('[Macro] 🗑️ Deleted custom button.');
    notifyListeners();
  }

  void stopMacroPlayback() {
    if (_isPlayingMacro) {
      _isPlayingMacro = false;
      _playingMacroTitle = null;
      _playingStepIndex = 0;
      _playbackStatusMessage = '';
      _addLog('[Macro] ⏹️ Playback stopped.');
      notifyListeners();
    }
  }

  Future<void> playMacro(MacroButton macro) async {
    if (_isPlayingMacro) return;

    _isPlayingMacro = true;
    _playingMacroTitle = macro.title;
    _playingStepIndex = 0;
    _playbackStatusMessage = 'Initializing playback...';
    notifyListeners();

    try {
      // 🚀 VERIFIED TV COMPANION MODE: If companion is connected to TV
      if (_companionClient.isConnected) {
        _addLog('[Macro] 🚀 TV Companion Connected! Using Verified Execution.');

        final titleLower = macro.title.toLowerCase();
        String? targetPackage;
        if (macro.id == 'default_settings' || titleLower.contains('setting')) {
          targetPackage = 'com.android.tv.settings';
        } else if (titleLower.contains('youtube')) {
          targetPackage = 'com.google.android.youtube.tv';
        } else if (titleLower.contains('camera')) {
          targetPackage = 'com.oneplus.tv.camera';
        }

        // Direct App Launch via Companion Accessibility Intent (0.1s!)
        if (targetPackage != null) {
          _playbackStatusMessage = 'Launching $targetPackage directly...';
          notifyListeners();
          final launched = await _companionClient.launchApp(targetPackage);
          if (launched) {
            _playbackStatusMessage = 'Verifying TV screen...';
            notifyListeners();
            await _companionClient.verifyScreen(targetPackage, timeoutMs: 3000);
            _addLog('[Macro] ✅ Verified TV opened $targetPackage!');
            return;
          }
        }

        // Companion Global Home reset + verified screen anchor
        _playbackStatusMessage = 'Resetting TV to Home via Companion...';
        notifyListeners();
        await _companionClient.sendGlobalAction('HOME');
        await Future.delayed(const Duration(milliseconds: 1000));
        await _companionClient.sendGlobalAction('HOME');
        await Future.delayed(const Duration(milliseconds: 1200));
      } else {
        // Fallback: Standard Bluetooth HID 2x Home Anchor Reset routine
        _playbackStatusMessage = 'Resetting TV: 1st HOME (exiting app)...';
        _addLog('[Macro] ▶️ Starting "${macro.title}". Performing 2x HOME anchor reset...');
        notifyListeners();

        // Step 1: 1st Home press (exits running app like YouTube, Netflix, Prime)
        if (_currentMode == RemoteEngineMode.wifi) {
          await _wifiService.sendKey(RemoteKey.home);
        } else {
          await _btService.sendKey(RemoteKey.home);
        }
        await Future.delayed(const Duration(milliseconds: 1500));
        if (!_isPlayingMacro) return;

        // Step 2: 2nd Home press (Android TV resets cursor to top-left anchor on launcher)
        _playbackStatusMessage = 'Resetting TV: 2nd HOME (cursor reset)...';
        notifyListeners();
        if (_currentMode == RemoteEngineMode.wifi) {
          await _wifiService.sendKey(RemoteKey.home);
        } else {
          await _btService.sendKey(RemoteKey.home);
        }

        // Step 3: Settle buffer delay (~2 seconds, so total reset wait is ~5s for heavy apps to exit)
        _playbackStatusMessage = 'Waiting for TV launcher to settle...';
        notifyListeners();
        await Future.delayed(const Duration(milliseconds: 2000));
        if (!_isPlayingMacro) return;
      }

      // Step 4: If macro has leading HOME keys from earlier recordings, skip them
      // since the 2x Home Anchor Reset has already placed the TV at the Home anchor.
      List<MacroStep> stepsToExecute = macro.steps;
      int firstNonHome = stepsToExecute.indexWhere((s) => s.key != RemoteKey.home);
      if (firstNonHome > 0) {
        stepsToExecute = stepsToExecute.sublist(firstNonHome);
      } else if (firstNonHome == -1) {
        // Macro contains only HOME keys
        stepsToExecute = [];
      }

      _addLog('[Macro] ▶️ Executing ${stepsToExecute.length} recorded steps (1s interval)...');

      for (int i = 0; i < stepsToExecute.length; i++) {
        if (!_isPlayingMacro) break; // User stopped or cancelled
        _playingStepIndex = i + 1;
        _playbackStatusMessage = 'Step ${i + 1} of ${stepsToExecute.length} (${stepsToExecute[i].key.name.toUpperCase()})...';
        notifyListeners();

        final step = stepsToExecute[i];
        HapticService.navigationClick();

        if (_currentMode == RemoteEngineMode.wifi) {
          await _wifiService.sendKey(step.key);
        } else {
          await _btService.sendKey(step.key);
        }

        // Play each step with at least 1 second interval
        final delay = step.delayMs < 1000 ? 1000 : step.delayMs;
        await Future.delayed(Duration(milliseconds: delay));
      }
      _addLog('[Macro] ✅ Finished "${macro.title}".');
    } catch (e) {
      _addLog('[Macro] Error playing macro: $e');
    } finally {
      _isPlayingMacro = false;
      _playingMacroTitle = null;
      _playingStepIndex = 0;
      _playbackStatusMessage = '';
      notifyListeners();
    }
  }

  /// Smart HDMI Switcher: Uses Ceiling-Anchor navigation or TV Companion direct click
  Future<void> switchHdmiInput(int hdmiPort) async {
    if (_isPlayingMacro) return;

    _isPlayingMacro = true;
    _playingMacroTitle = 'Switching to HDMI $hdmiPort';
    _playingStepIndex = 0;
    _playbackStatusMessage = 'Initiating Smart HDMI $hdmiPort Switch...';
    _addLog('[Input] 📺 Smart Switch: Target HDMI $hdmiPort');
    notifyListeners();

    try {
      // 1. If TV Companion is connected, attempt verified direct click
      if (_companionClient.isConnected) {
        _playbackStatusMessage = 'Companion: Clicking "HDMI $hdmiPort"...';
        notifyListeners();
        final clicked = await _companionClient.clickText('HDMI $hdmiPort');
        if (clicked) {
          _addLog('[Input] ✅ Directly switched to HDMI $hdmiPort via Companion click!');
          return;
        }
      }

      // 2. Ceiling-Anchor Navigation (Works reliably via Bluetooth HID / Wi-Fi)
      // Step A: Open Inputs Menu
      _playbackStatusMessage = 'Step 1/4: Opening Inputs Menu...';
      notifyListeners();
      if (_currentMode == RemoteEngineMode.wifi) {
        await _wifiService.sendKey(RemoteKey.input);
      } else {
        await _btService.sendKey(RemoteKey.input);
      }
      await Future.delayed(const Duration(milliseconds: 700));

      // Step B: Press UP 5 times to hit top boundary/ceiling (anchors reliably on DTV)
      _playbackStatusMessage = 'Step 2/4: Aligning cursor to Top (DTV)...';
      notifyListeners();
      for (int i = 0; i < 5; i++) {
        if (!_isPlayingMacro) return;
        if (_currentMode == RemoteEngineMode.wifi) {
          await _wifiService.sendKey(RemoteKey.dpadUp);
        } else {
          await _btService.sendKey(RemoteKey.dpadUp);
        }
        await Future.delayed(const Duration(milliseconds: 160));
      }
      await Future.delayed(const Duration(milliseconds: 250));

      // Step C: Press DOWN to reach target:
      // Menu list: 0: DTV, 1: ATV, 2: Composite, 3: HDMI 1, 4: HDMI 2, 5: Android TV Home
      final downCount = hdmiPort == 1 ? 3 : 4;
      _playbackStatusMessage = 'Step 3/4: Navigating to HDMI $hdmiPort ($downCount down)...';
      notifyListeners();
      for (int i = 0; i < downCount; i++) {
        if (!_isPlayingMacro) return;
        if (_currentMode == RemoteEngineMode.wifi) {
          await _wifiService.sendKey(RemoteKey.dpadDown);
        } else {
          await _btService.sendKey(RemoteKey.dpadDown);
        }
        await Future.delayed(const Duration(milliseconds: 200));
      }
      await Future.delayed(const Duration(milliseconds: 300));

      // Step D: Confirm selection with ENTER (ok)
      _playbackStatusMessage = 'Step 4/4: Confirming HDMI $hdmiPort...';
      notifyListeners();
      if (_currentMode == RemoteEngineMode.wifi) {
        await _wifiService.sendKey(RemoteKey.ok);
      } else {
        await _btService.sendKey(RemoteKey.ok);
      }
      _addLog('[Input] ✅ Successfully switched to HDMI $hdmiPort via Ceiling Anchor!');
    } catch (e) {
      _addLog('[Input] Error switching HDMI $hdmiPort: $e');
    } finally {
      _isPlayingMacro = false;
      _playingMacroTitle = null;
      _playingStepIndex = 0;
      _playbackStatusMessage = '';
      notifyListeners();
    }
  }

  Future<void> scanForWifiTvs() async {
    _discoveredDevices.clear();
    notifyListeners();

    final list = await _wifiService.discoverDevices();
    _discoveredDevices.addAll(list);
    notifyListeners();
  }

  Future<void> connectWifiTv(TvDevice device) async {
    _selectedTv = device;
    notifyListeners();
    await _wifiService.connect(device);
  }

  Future<void> startWifiPairing(TvDevice device) async {
    _selectedTv = device;
    notifyListeners();
    await _wifiService.startPairing(device);
  }

  Future<bool> submitWifiPin(String pin) async {
    return await _wifiService.sendPairingSecret(pin);
  }

  Future<List<Map<String, String>>> getBondedBtDevices() async {
    return await _btService.getBondedDevices();
  }

  Future<void> connectBtDevice(String address, String name) async {
    _status = ConnectionStatus.connecting;
    notifyListeners();
    final ok = await _btService.connectDevice(address);
    if (ok) {
      _status = ConnectionStatus.connected;
    }
    notifyListeners();
  }

  Future<void> disconnect() async {
    if (_currentMode == RemoteEngineMode.wifi) {
      _wifiService.disconnect();
    } else {
      await _btService.disconnect();
    }
    _status = ConnectionStatus.disconnected;
    notifyListeners();
  }

  Future<bool> connectCompanion(String host, {int port = 8765}) async {
    final ok = await _companionClient.connect(host, port: port);
    notifyListeners();
    return ok;
  }

  Future<void> disconnectCompanion() async {
    await _companionClient.disconnect();
    notifyListeners();
  }

  Future<void> sendText(String text) async {
    if (text.isEmpty) return;
    HapticService.buttonClick();
    _addLog('[Keyboard] Typing text: "$text"');

    if (_currentMode == RemoteEngineMode.wifi) {
      // Send text via Wi-Fi remote
      _addLog('[Wi-Fi] Sending text "$text" to TV');
    } else {
      await _btService.sendText(text);
    }
  }

  Future<void> autoTypeApkUrlOnTv() async {
    if (!_localServer.isRunning) {
      await _localServer.start();
    }
    final url = _localServer.downloadUrl;
    if (url.isEmpty) {
      _addLog('[Keyboard] ⚠️ Cannot auto-type URL: Local IP not available');
      return;
    }

    _addLog('[Keyboard] 🌐 Streaming download URL to TV: $url');
    await sendText(url);
    await Future.delayed(const Duration(milliseconds: 350));
    // Send Enter (OK) to navigate to the link in the TV browser
    if (_currentMode == RemoteEngineMode.wifi) {
      await _wifiService.sendKey(RemoteKey.ok);
    } else {
      await _btService.sendKey(RemoteKey.ok);
    }
  }

  @override
  void dispose() {
    _wifiStatusSub?.cancel();
    _btStatusSub?.cancel();
    _wifiLogSub?.cancel();
    _btLogSub?.cancel();
    _companionClient.removeListener(notifyListeners);
    _localServer.removeListener(notifyListeners);
    _localServer.stop();
    _wifiService.dispose();
    _btService.dispose();
    super.dispose();
  }
}
