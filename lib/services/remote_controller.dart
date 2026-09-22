import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/remote_key.dart';
import '../models/connection_mode.dart';
import '../models/tv_device.dart';
import 'wifi_remote_service.dart';
import 'bluetooth_hid_service.dart';
import 'haptic_service.dart';

class RemoteController extends ChangeNotifier {
  final WifiRemoteService _wifiService = WifiRemoteService();
  final BluetoothHidService _btService = BluetoothHidService();

  RemoteEngineMode _currentMode = RemoteEngineMode.wifi;
  RemoteEngineMode get currentMode => _currentMode;

  ConnectionStatus _status = ConnectionStatus.disconnected;
  ConnectionStatus get status => _status;

  TvDevice? _selectedTv;
  TvDevice? get selectedTv => _selectedTv;

  final List<TvDevice> _discoveredDevices = [];
  List<TvDevice> get discoveredDevices => List.unmodifiable(_discoveredDevices);

  final List<String> _recentLogs = [];
  List<String> get recentLogs => List.unmodifiable(_recentLogs);

  StreamSubscription? _wifiStatusSub;
  StreamSubscription? _btStatusSub;
  StreamSubscription? _wifiLogSub;
  StreamSubscription? _btLogSub;

  RemoteController() {
    _initListeners();
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

    if (_currentMode == RemoteEngineMode.wifi) {
      await _wifiService.sendKey(key);
    } else {
      await _btService.sendKey(key);
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
