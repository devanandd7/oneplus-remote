import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

class TvScreenState {
  final String package;
  final String activity;
  final String focused;
  final bool isAccessibilityActive;
  final DateTime timestamp;

  const TvScreenState({
    required this.package,
    required this.activity,
    required this.focused,
    required this.isAccessibilityActive,
    required this.timestamp,
  });

  factory TvScreenState.initial() => TvScreenState(
        package: '',
        activity: '',
        focused: '',
        isAccessibilityActive: false,
        timestamp: DateTime.now(),
      );

  factory TvScreenState.fromJson(Map<String, dynamic> json) {
    return TvScreenState(
      package: json['package'] as String? ?? '',
      activity: json['activity'] as String? ?? '',
      focused: json['focused'] as String? ?? '',
      isAccessibilityActive: json['accessibilityActive'] as bool? ?? false,
      timestamp: DateTime.now(),
    );
  }

  bool get isHome =>
      package.contains('launcher') || package.contains('tvlauncher');

  bool get isYouTube => package.contains('youtube');

  bool get isSettings => package.contains('settings');

  String get displayName {
    if (isHome) return 'TV Home';
    if (isYouTube) return 'YouTube';
    if (isSettings) return 'Settings';
    if (package.isEmpty) return 'Standby';
    final parts = package.split('.');
    return parts.isNotEmpty ? parts.last.toUpperCase() : package;
  }
}

class TvCompanionClient with ChangeNotifier {
  static final TvCompanionClient _instance = TvCompanionClient._internal();
  factory TvCompanionClient() => _instance;
  TvCompanionClient._internal();

  WebSocket? _socket;
  String? _connectedIp;
  int _connectedPort = 8765;
  bool _isConnected = false;
  bool _isConnecting = false;

  TvScreenState _currentState = TvScreenState.initial();
  final Map<String, Completer<Map<String, dynamic>>> _pendingRequests = {};
  int _requestCounter = 0;

  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  String? get connectedIp => _connectedIp;
  int get connectedPort => _connectedPort;
  TvScreenState get currentState => _currentState;

  final _stateController = StreamController<TvScreenState>.broadcast();
  Stream<TvScreenState> get onStateChanged => _stateController.stream;

  final _logController = StreamController<String>.broadcast();
  Stream<String> get onLog => _logController.stream;

  void _log(String msg) {
    debugPrint('[TvCompanion] $msg');
    _logController.add(msg);
  }

  Future<bool> connect(String host, {int port = 8765}) async {
    if (_isConnected && _connectedIp == host && _connectedPort == port) {
      return true;
    }

    await disconnect();
    _isConnecting = true;
    notifyListeners();

    try {
      final uri = 'ws://$host:$port';
      _log('Connecting to TV Companion at $uri...');
      _socket = await WebSocket.connect(uri).timeout(
        const Duration(seconds: 4),
      );

      _connectedIp = host;
      _connectedPort = port;
      _isConnected = true;
      _isConnecting = false;
      _log(' Connected to TV Companion ($host:$port)!');
      notifyListeners();

      _socket!.listen(
        _onMessageReceived,
        onError: (err) {
          _log('Socket error: $err');
          _handleDisconnect();
        },
        onDone: () {
          _log('Socket connection closed by TV');
          _handleDisconnect();
        },
      );

      // Fetch initial state
      await getState();
      return true;
    } catch (e) {
      _log('Failed to connect to TV: $e');
      _handleDisconnect();
      return false;
    }
  }

  void _handleDisconnect() {
    _isConnected = false;
    _isConnecting = false;
    _socket = null;
    notifyListeners();
  }

  Future<void> disconnect() async {
    try {
      await _socket?.close();
    } catch (_) {}
    _handleDisconnect();
  }

  void _onMessageReceived(dynamic raw) {
    try {
      final Map<String, dynamic> data = jsonDecode(raw as String);
      final type = data['type'] as String? ?? '';
      final requestId = data['requestId'] as String?;

      if (requestId != null && _pendingRequests.containsKey(requestId)) {
        _pendingRequests.remove(requestId)?.complete(data);
      }

      if (type == 'STATE_UPDATE' || type == 'WELCOME' || type == 'STATE') {
        _currentState = TvScreenState.fromJson(data);
        _stateController.add(_currentState);
        _log(
            'Screen Update: ${_currentState.displayName} (Focused: "${_currentState.focused}")');
        notifyListeners();
      }
    } catch (e) {
      _log('Error parsing incoming message: $e');
    }
  }

  Future<Map<String, dynamic>> _sendAction(
    Map<String, dynamic> payload, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    if (!_isConnected || _socket == null) {
      throw Exception('TV Companion is not connected');
    }

    final reqId = 'req_${++_requestCounter}';
    payload['requestId'] = reqId;

    final completer = Completer<Map<String, dynamic>>();
    _pendingRequests[reqId] = completer;

    _socket!.add(jsonEncode(payload));

    return completer.future.timeout(
      timeout,
      onTimeout: () {
        _pendingRequests.remove(reqId);
        throw TimeoutException('Request $reqId timed out');
      },
    );
  }

  Future<TvScreenState> getState() async {
    try {
      final res = await _sendAction({'action': 'GET_STATE'});
      _currentState = TvScreenState.fromJson(res);
      notifyListeners();
      return _currentState;
    } catch (e) {
      _log('Error getting state: $e');
      return _currentState;
    }
  }

  Future<bool> launchApp(String packageName) async {
    try {
      _log('Launching TV App: $packageName');
      final res = await _sendAction({
        'action': 'LAUNCH_APP',
        'package': packageName,
      });
      return res['success'] == true;
    } catch (e) {
      _log('Launch app failed: $e');
      return false;
    }
  }

  Future<bool> clickText(String text) async {
    try {
      _log('Clicking TV element: "$text"');
      final res = await _sendAction({
        'action': 'CLICK_TEXT',
        'text': text,
      });
      return res['success'] == true;
    } catch (e) {
      _log('Click text failed: $e');
      return false;
    }
  }

  Future<bool> sendGlobalAction(String key) async {
    try {
      _log('Sending TV Global Action: $key');
      final res = await _sendAction({
        'action': 'GLOBAL_ACTION',
        'key': key,
      });
      return res['success'] == true;
    } catch (e) {
      _log('Global action failed: $e');
      return false;
    }
  }

  Future<bool> verifyScreen(String expectedPackage,
      {int timeoutMs = 4000}) async {
    try {
      _log(
          'Verifying screen matches "$expectedPackage" (timeout: ${timeoutMs}ms)...');
      final res = await _sendAction({
        'action': 'VERIFY_SCREEN',
        'expectedPackage': expectedPackage,
        'timeoutMs': timeoutMs,
      }, timeout: Duration(milliseconds: timeoutMs + 1500));
      return res['matched'] == true;
    } catch (e) {
      _log('Verification failed: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _socket?.close();
    _stateController.close();
    _logController.close();
    super.dispose();
  }
}
