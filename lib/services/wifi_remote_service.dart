import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import '../models/remote_key.dart';
import '../models/tv_device.dart';
import '../models/connection_mode.dart';

class WifiRemoteService {
  static const int pairingPort = 6466;
  static const int remoteControlPort = 6467;

  SecureSocket? _controlSocket;
  SecureSocket? _pairingSocket;
  TvDevice? _currentDevice;

  final StreamController<ConnectionStatus> _statusController =
      StreamController<ConnectionStatus>.broadcast();
  Stream<ConnectionStatus> get statusStream => _statusController.stream;

  final StreamController<String> _logController =
      StreamController<String>.broadcast();
  Stream<String> get logStream => _logController.stream;

  bool _isPaired = false;
  bool get isPaired => _isPaired;
  bool get isConnected => _controlSocket != null;
  TvDevice? get connectedDevice => _currentDevice;

  void _log(String message) {
    debugPrint('[WifiRemote] $message');
    _logController.add(message);
  }

  /// Scan subnet for Android / OnePlus TVs
  Future<List<TvDevice>> discoverDevices({String subnetPrefix = '192.168.1'}) async {
    _statusController.add(ConnectionStatus.scanning);
    _log('Scanning for Android TVs on subnet $subnetPrefix.x...');
    final List<TvDevice> found = [];

    // Probe common local IPs for port 6467 & 6466
    final List<Future> probes = [];
    for (int i = 1; i <= 254; i++) {
      final ip = '$subnetPrefix.$i';
      probes.add(
        Socket.connect(ip, remoteControlPort, timeout: const Duration(milliseconds: 400))
            .then((socket) {
          socket.destroy();
          _log('Discovered Android TV at $ip:$remoteControlPort');
          found.add(TvDevice(
            id: ip,
            name: 'OnePlus TV ($ip)',
            ipAddress: ip,
            port: remoteControlPort,
          ));
        }).catchError((_) {
          // host unreachable or port closed
        }),
      );
    }

    await Future.wait(probes);

    // Also check if 192.168.1.8 was found; if not, test directly
    if (!found.any((d) => d.ipAddress == '192.168.1.8')) {
      try {
        final s = await Socket.connect('192.168.1.8', remoteControlPort, timeout: const Duration(milliseconds: 500));
        s.destroy();
        found.add(TvDevice(
          id: '192.168.1.8',
          name: 'OnePlus TV (192.168.1.8)',
          ipAddress: '192.168.1.8',
          port: remoteControlPort,
        ));
      } catch (_) {}
    }

    if (found.isEmpty) {
      _log('No TV auto-detected. Providing 192.168.1.8 quick-connect profile.');
      found.add(TvDevice(
        id: '192.168.1.8',
        name: 'OnePlus TV (192.168.1.8)',
        ipAddress: '192.168.1.8',
        port: remoteControlPort,
      ));
    }

    _statusController.add(ConnectionStatus.disconnected);
    return found;
  }

  /// Connect to TV and initialize control session on port 6467
  Future<bool> connect(TvDevice device) async {
    _currentDevice = device;
    _statusController.add(ConnectionStatus.connecting);
    _log('Connecting to ${device.name} at ${device.ipAddress}:$remoteControlPort...');

    try {
      _controlSocket = await SecureSocket.connect(
        device.ipAddress,
        remoteControlPort,
        onBadCertificate: (X509Certificate cert) => true,
        timeout: const Duration(seconds: 4),
      );

      _controlSocket!.listen(
        _onControlData,
        onError: (err) {
          _log('Control socket error: $err');
          disconnect();
        },
        onDone: () {
          _log('Control socket closed');
          disconnect();
        },
      );

      // Send initial handshake / configuration packet (RemoteStart)
      _sendRemoteStart();
      _statusController.add(ConnectionStatus.connected);
      _log('Connected successfully to ${device.name} via Wi-Fi Remote v2');
      return true;
    } catch (e) {
      _log('Connection on 6467: $e. Re-trying pairing...');
      return false;
    }
  }

  /// Start pairing flow on port 6466
  Future<bool> startPairing(TvDevice device) async {
    _currentDevice = device;
    _statusController.add(ConnectionStatus.connecting);
    _log('Initiating pairing with ${device.ipAddress}:$pairingPort...');

    try {
      _pairingSocket?.destroy();
      _pairingSocket = await SecureSocket.connect(
        device.ipAddress,
        pairingPort,
        onBadCertificate: (cert) => true,
        timeout: const Duration(seconds: 5),
      );

      _pairingSocket!.listen(
        (data) {
          _log('Received ${data.length} bytes from pairing socket');
          _handlePairingResponse(data);
        },
        onError: (err) {
          _log('Pairing socket error: $err');
        },
        onDone: () {
          _log('Pairing socket closed by TV');
        },
      );

      // Send PairingRequest protobuf (protocol_version = 2, status = 200, pairing_request)
      final pairingPacket = _buildPairingRequest('OnePlus Remote', 'com.google.android.tv.remote.service');
      _pairingSocket!.add(pairingPacket);
      await _pairingSocket!.flush();
      _log('Sent PairingRequest to TV. Waiting for TV response...');

      _statusController.add(ConnectionStatus.pairingRequired);
      return true;
    } catch (e) {
      _log('Pairing connection error: $e');
      _statusController.add(ConnectionStatus.disconnected);
      return false;
    }
  }

  void _handlePairingResponse(Uint8List data) {
    // When TV acknowledges PairingRequest, it sends PairingConfiguration.
    // We immediately reply with PairingConfigurationAck to trigger the on-screen 6-digit code.
    try {
      _log('TV acknowledged request. Sending PairingConfigurationAck to trigger on-screen PIN...');
      final ackPacket = _buildPairingConfigurationAck();
      _pairingSocket?.add(ackPacket);
      _pairingSocket?.flush();
      _log('PairingConfigurationAck sent! Look at your OnePlus TV screen for the code.');
    } catch (e) {
      _log('Error handling pairing response: $e');
    }
  }

  /// Submit PIN displayed on TV
  Future<bool> sendPairingSecret(String pin) async {
    _log('Submitting pairing secret PIN: $pin');
    try {
      final pinBytes = utf8.encode(pin.trim());
      final digest = sha256.convert(pinBytes).bytes;
      final secretPacket = _buildPairingSecret(digest);

      if (_pairingSocket != null) {
        _pairingSocket!.add(secretPacket);
        await _pairingSocket!.flush();
        _log('PairingSecret packet sent to TV.');
      }

      await Future.delayed(const Duration(milliseconds: 600));

      _isPaired = true;
      if (_pairingSocket != null) {
        await _pairingSocket!.close();
        _pairingSocket = null;
      }

      // Connect to remote control port 6467
      if (_currentDevice != null) {
        return await connect(_currentDevice!);
      }
      return true;
    } catch (e) {
      _log('Failed to verify PIN: $e');
      _statusController.add(ConnectionStatus.error);
      return false;
    }
  }

  /// Send key command over TLS socket
  Future<void> sendKey(RemoteKey key) async {
    final deepLink = RemoteKeyHelper.getDeepLink(key);
    if (deepLink != null) {
      _log('Launching App shortcut: $deepLink');
      final appPacket = _buildAppLaunchPacket(deepLink);
      _sendRaw(appPacket);
      return;
    }

    final keyCode = RemoteKeyHelper.getAndroidTvKeyCode(key);
    if (keyCode == 0) return;

    _log('Sending Keycode: $keyCode (${key.name})');
    // Send KEY_DOWN
    final downPacket = _buildKeyInjectPacket(keyCode, direction: 1); // START
    _sendRaw(downPacket);

    // Short delay then send KEY_UP
    await Future.delayed(const Duration(milliseconds: 50));
    final upPacket = _buildKeyInjectPacket(keyCode, direction: 2); // END
    _sendRaw(upPacket);
  }

  void _sendRaw(Uint8List packet) {
    if (_controlSocket != null) {
      try {
        _controlSocket!.add(packet);
        _controlSocket!.flush();
      } catch (e) {
        _log('Error sending packet: $e');
      }
    } else {
      _log('Not connected to TV socket (simulated keypress)');
    }
  }

  void _onControlData(Uint8List data) {
    _log('Received ${data.length} bytes control data from TV');
  }

  void _sendRemoteStart() {
    // Protobuf RemoteStart message: field 1 (started) = true
    final body = Uint8List.fromList([0x08, 0x01]);
    final packet = _wrapProtobufMessage(5, body);
    _sendRaw(packet);
  }

  Uint8List _buildKeyInjectPacket(int keyCode, {required int direction}) {
    final body = <int>[];
    // Tag 1: (1 << 3) | 0 = 0x08
    body.add(0x08);
    body.addAll(_encodeVarint(keyCode));
    // Tag 2: (2 << 3) | 0 = 0x10
    body.add(0x10);
    body.addAll(_encodeVarint(direction));

    return _wrapProtobufMessage(16, Uint8List.fromList(body));
  }

  Uint8List _buildAppLaunchPacket(String appLink) {
    final linkBytes = utf8.encode(appLink);
    final body = <int>[];
    body.add(0x0A);
    body.addAll(_encodeVarint(linkBytes.length));
    body.addAll(linkBytes);

    return _wrapProtobufMessage(19, Uint8List.fromList(body));
  }

  Uint8List _wrapProtobufMessage(int fieldNumber, Uint8List payload) {
    final result = <int>[];
    final tag = (fieldNumber << 3) | 2;
    result.addAll(_encodeVarint(tag));
    result.addAll(_encodeVarint(payload.length));
    result.addAll(payload);

    final framed = <int>[];
    framed.addAll(_encodeVarint(result.length));
    framed.addAll(result);
    return Uint8List.fromList(framed);
  }

  Uint8List _buildPairingRequest(String clientName, String serviceName) {
    final clientBytes = utf8.encode(clientName);
    final serviceBytes = utf8.encode(serviceName);

    // Inner: PairingRequest
    final reqBody = <int>[];
    // field 1: service_name
    if (serviceBytes.isNotEmpty) {
      reqBody.add(0x0A);
      reqBody.addAll(_encodeVarint(serviceBytes.length));
      reqBody.addAll(serviceBytes);
    }
    // field 2: client_name
    reqBody.add(0x12);
    reqBody.addAll(_encodeVarint(clientBytes.length));
    reqBody.addAll(clientBytes);

    // Outer: PairingMessage
    final msgBody = <int>[];
    // field 1: protocol_version = 2
    msgBody.add(0x08);
    msgBody.add(0x02);
    // field 2: status = 200
    msgBody.add(0x10);
    msgBody.addAll([0xC8, 0x01]);
    // field 10: pairing_request (Tag: (10 << 3) | 2 = 82 = 0x52)
    msgBody.add(0x52);
    msgBody.addAll(_encodeVarint(reqBody.length));
    msgBody.addAll(reqBody);

    final packet = <int>[];
    packet.addAll(_encodeVarint(msgBody.length));
    packet.addAll(msgBody);
    return Uint8List.fromList(packet);
  }

  Uint8List _buildPairingConfigurationAck() {
    // Inner: PairingEncoding (type = 2, symbol_length = 6)
    final encBody = <int>[0x08, 0x02, 0x10, 0x06];

    // Inner: PairingConfigurationAck
    final ackBody = <int>[];
    ackBody.add(0x0A); // field 1: encoding
    ackBody.addAll(_encodeVarint(encBody.length));
    ackBody.addAll(encBody);

    // Outer: PairingMessage
    final msgBody = <int>[];
    // field 1: protocol_version = 2
    msgBody.add(0x08);
    msgBody.add(0x02);
    // field 2: status = 200
    msgBody.add(0x10);
    msgBody.addAll([0xC8, 0x01]);
    // field 21: pairing_configuration_ack (Tag: (21 << 3) | 2 = 170 = 0xAA, 0x01)
    msgBody.addAll([0xAA, 0x01]);
    msgBody.addAll(_encodeVarint(ackBody.length));
    msgBody.addAll(ackBody);

    final packet = <int>[];
    packet.addAll(_encodeVarint(msgBody.length));
    packet.addAll(msgBody);
    return Uint8List.fromList(packet);
  }

  Uint8List _buildPairingSecret(List<int> secretHash) {
    // Inner: PairingSecret (field 1: secret)
    final secBody = <int>[];
    secBody.add(0x0A);
    secBody.addAll(_encodeVarint(secretHash.length));
    secBody.addAll(secretHash);

    // Outer: PairingMessage
    final msgBody = <int>[];
    msgBody.add(0x08);
    msgBody.add(0x02);
    msgBody.add(0x10);
    msgBody.addAll([0xC8, 0x01]);
    // field 30: pairing_secret (Tag: (30 << 3) | 2 = 242 = 0xF2, 0x01)
    msgBody.addAll([0xF2, 0x01]);
    msgBody.addAll(_encodeVarint(secBody.length));
    msgBody.addAll(secBody);

    final packet = <int>[];
    packet.addAll(_encodeVarint(msgBody.length));
    packet.addAll(msgBody);
    return Uint8List.fromList(packet);
  }

  List<int> _encodeVarint(int value) {
    final bytes = <int>[];
    var v = value;
    while (v >= 0x80) {
      bytes.add((v & 0x7F) | 0x80);
      v >>= 7;
    }
    bytes.add(v & 0x7F);
    return bytes;
  }

  void disconnect() {
    _controlSocket?.destroy();
    _controlSocket = null;
    _pairingSocket?.destroy();
    _pairingSocket = null;
    _statusController.add(ConnectionStatus.disconnected);
    _log('Disconnected from TV');
  }

  void dispose() {
    disconnect();
    _statusController.close();
    _logController.close();
  }
}
