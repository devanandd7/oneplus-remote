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

class RemoteController extends ChangeNotifier {
  final WifiRemoteService _wifiService = WifiRemoteService();
  final BluetoothHidService _btService = BluetoothHidService();

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

  StreamSubscription? _wifiStatusSub;
  StreamSubscription? _btStatusSub;
  StreamSubscription? _wifiLogSub;
  StreamSubscription? _btLogSub;

  RemoteController() {
    _initListeners();
    _btService.initialize();
    loadSavedMacros();
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
              const MacroStep(key: RemoteKey.settings, delayMs: 300),
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
    // Step 1 is always HOME to ensure a stable reference point on the TV
    _recordedSteps.add(RemoteKey.home);
    _addLog('[Macro] 🔴 Recording started. Sent HOME reset to TV.');
    notifyListeners();

    // Send Home to TV so it resets to the launcher immediately
    if (_currentMode == RemoteEngineMode.wifi) {
      await _wifiService.sendKey(RemoteKey.home);
    } else {
      await _btService.sendKey(RemoteKey.home);
    }
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
    int stepDelayMs = 280,
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

  Future<void> playMacro(MacroButton macro) async {
    if (_isPlayingMacro) return;

    _isPlayingMacro = true;
    _playingMacroTitle = macro.title;
    _playingStepIndex = 0;
    _addLog('[Macro] ▶️ Executing "${macro.title}" (${macro.steps.length} steps)...');
    notifyListeners();

    try {
      for (int i = 0; i < macro.steps.length; i++) {
        if (!_isPlayingMacro) break; // User stopped or cancelled
        _playingStepIndex = i + 1;
        notifyListeners();

        final step = macro.steps[i];
        HapticService.navigationClick();

        if (_currentMode == RemoteEngineMode.wifi) {
          await _wifiService.sendKey(step.key);
        } else {
          await _btService.sendKey(step.key);
        }

        await Future.delayed(Duration(milliseconds: step.delayMs));
      }
      _addLog('[Macro] ✅ Finished "${macro.title}".');
    } catch (e) {
      _addLog('[Macro] Error playing macro: $e');
    } finally {
      _isPlayingMacro = false;
      _playingMacroTitle = null;
      _playingStepIndex = 0;
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

  @override
  void dispose() {
    _wifiStatusSub?.cancel();
    _btStatusSub?.cancel();
    _wifiLogSub?.cancel();
    _btLogSub?.cancel();
    _wifiService.dispose();
    _btService.dispose();
    super.dispose();
  }
}
