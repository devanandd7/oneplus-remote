import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../models/remote_key.dart';
import '../models/connection_mode.dart';

class BluetoothHidService {
  static const MethodChannel _methodChannel = MethodChannel('oneplus_remote/hid');
  static const EventChannel _eventChannel = EventChannel('oneplus_remote/hid_events');

  final StreamController<ConnectionStatus> _statusController =
      StreamController<ConnectionStatus>.broadcast();
  Stream<ConnectionStatus> get statusStream => _statusController.stream;

  final StreamController<String> _logController =
      StreamController<String>.broadcast();
  Stream<String> get logStream => _logController.stream;

  StreamSubscription? _eventSubscription;
  bool _isInitialized = false;
  String? _connectedDeviceName;
  String? get connectedDeviceName => _connectedDeviceName;

  void _log(String msg) {
    debugPrint('[BluetoothHID] $msg');
    _logController.add(msg);
  }

  Future<bool> initialize() async {
    _log('Initializing Bluetooth HID Device profile...');
    try {
      _listenToEvents();
      final bool? success = await _methodChannel.invokeMethod<bool>('initializeHid');
      _isInitialized = success ?? false;
      _log('HID Profile initialized: $_isInitialized');
      if (_isInitialized) {
        _statusController.add(ConnectionStatus.connecting);
      }
      return _isInitialized;
    } on MissingPluginException {
      _log('Bluetooth HID native platform channel unavailable (running on simulator or non-Android). Emulating HID profile.');
      _isInitialized = true;
      _statusController.add(ConnectionStatus.connected);
      return true;
    } catch (e) {
      _log('Error initializing HID: $e');
      _statusController.add(ConnectionStatus.error);
      return false;
    }
  }

  void _listenToEvents() {
    _eventSubscription?.cancel();
    _eventSubscription = _eventChannel.receiveBroadcastStream().listen(
      (dynamic event) {
        if (event is Map) {
          final state = event['state'] as String? ?? '';
          final deviceName = event['deviceName'] as String? ?? '';
          _connectedDeviceName = deviceName.isNotEmpty ? deviceName : null;
          _log('Native HID Event: $state (Device: $deviceName)');

          switch (state) {
            case 'CONNECTED':
              _statusController.add(ConnectionStatus.connected);
              break;
            case 'CONNECTING':
              _statusController.add(ConnectionStatus.connecting);
              break;
            case 'READY_TO_PAIR':
              _log('Device is advertising as "OnePlus TV Remote". Pair it under TV Settings -> Remotes & Accessories.');
              _statusController.add(ConnectionStatus.connecting);
              break;
            case 'DISCONNECTED':
              _statusController.add(ConnectionStatus.disconnected);
              break;
            default:
              break;
          }
        }
      },
      onError: (err) {
        _log('HID EventChannel error: $err');
      },
    );
  }

  Future<void> sendKey(RemoteKey key) async {
    final keyName = RemoteKeyHelper.getHidKeyName(key);
    if (keyName.isEmpty) {
      _log('Key ${key.name} not supported over standard Bluetooth HID');
      return;
    }

    _log('Sending HID Key: $keyName');
    try {
      await _methodChannel.invokeMethod('sendKey', {'key': keyName});
    } on MissingPluginException {
      _log('Emulated HID Key: $keyName sent');
    } catch (e) {
      _log('Failed to send HID key: $e');
    }
  }

  Future<List<Map<String, String>>> getBondedDevices() async {
    try {
      final List? list = await _methodChannel.invokeMethod<List>('getBondedDevices');
      if (list != null) {
        return list.map((item) => Map<String, String>.from(item as Map)).toList();
      }
    } catch (e) {
      _log('getBondedDevices error: $e');
    }
    return [];
  }

  Future<bool> connectDevice(String address) async {
    _log('Connecting to Bluetooth device: $address');
    try {
      final bool? success = await _methodChannel.invokeMethod<bool>(
        'connectDevice',
        {'address': address},
      );
      return success ?? false;
    } catch (e) {
      _log('connectDevice error: $e');
      return false;
    }
  }

  Future<void> disconnect() async {
    try {
      await _methodChannel.invokeMethod('unregisterHid');
    } catch (_) {}
    _statusController.add(ConnectionStatus.disconnected);
  }

  void dispose() {
    _eventSubscription?.cancel();
    _statusController.close();
    _logController.close();
  }
}
