import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

class LocalApkServerService with ChangeNotifier {
  static final LocalApkServerService _instance =
      LocalApkServerService._internal();
  factory LocalApkServerService() => _instance;
  LocalApkServerService._internal();

  HttpServer? _server;
  int _port = 8080;
  String? _localIp;
  bool _isRunning = false;

  bool get isRunning => _isRunning;
  int get port => _port;
  String? get localIp => _localIp;

  String get downloadUrl =>
      _localIp != null ? 'http://$_localIp:$_port/download' : '';
  String get webUrl => _localIp != null ? 'http://$_localIp:$_port' : '';

  final _logController = StreamController<String>.broadcast();
  Stream<String> get onLog => _logController.stream;

  void _log(String msg) {
    debugPrint('[LocalApkServer] $msg');
    _logController.add(msg);
  }

  Future<bool> start({int port = 8080}) async {
    if (_isRunning) return true;

    try {
      _localIp = await _findLocalIpAddress();
      _port = port;

      _server = await HttpServer.bind(InternetAddress.anyIPv4, _port);
      _isRunning = true;
      _log('🚀 Local Web Server started at $webUrl');
      notifyListeners();

      _server!.listen(_handleRequest, onError: (err) {
        _log('Server error: $err');
      });

      return true;
    } catch (e) {
      _log('Failed to start server on port $port: $e');
      // Try fallback port 8081 if 8080 is in use
      if (port == 8080) {
        return await start(port: 8081);
      }
      _isRunning = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> stop() async {
    try {
      await _server?.close(force: true);
      _server = null;
      _isRunning = false;
      _log('Local Web Server stopped.');
      notifyListeners();
    } catch (e) {
      _log('Error stopping server: $e');
    }
  }

  Future<String> _findLocalIpAddress() async {
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );

      // Prioritize Wi-Fi and Hotspot interfaces
      for (final iface in interfaces) {
        final name = iface.name.toLowerCase();
        for (final addr in iface.addresses) {
          if (!addr.isLoopback &&
              (name.contains('wlan') ||
                  name.contains('wi-fi') ||
                  name.contains('ap') ||
                  name.contains('rndis') ||
                  name.contains('eth'))) {
            return addr.address;
          }
        }
      }

      // Fallback: take first non-loopback IPv4
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback) {
            return addr.address;
          }
        }
      }
    } catch (e) {
      _log('Error finding local IP: $e');
    }
    return '127.0.0.1';
  }

  Future<void> refreshIp() async {
    _localIp = await _findLocalIpAddress();
    notifyListeners();
  }

  Future<void> _handleRequest(HttpRequest request) async {
    final path = request.uri.path;
    _log('Request: ${request.method} $path from ${request.connectionInfo?.remoteAddress.address}');

    // Enable CORS
    request.response.headers.add('Access-Control-Allow-Origin', '*');

    if (path == '/favicon.ico') {
      request.response.statusCode = HttpStatus.noContent;
      await request.response.close();
      return;
    }

    if (path == '/download' || path.endsWith('.apk')) {
      await _serveApk(request);
    } else {
      _serveLandingPage(request);
    }
  }

  Future<void> _serveApk(HttpRequest request) async {
    try {
      Uint8List? apkBytes;

      // 1. Try to read from assets folder
      try {
        final byteData = await rootBundle.load('assets/OnePlusTvCompanion.apk');
        apkBytes = byteData.buffer.asUint8List();
      } catch (_) {
        // Fallback: Check local filesystem
        const paths = [
          'OnePlusTvCompanion.apk',
          'assets/OnePlusTvCompanion.apk',
          'tv_companion/app/build/outputs/apk/debug/app-debug.apk',
        ];
        for (final p in paths) {
          final file = File(p);
          if (await file.exists()) {
            apkBytes = await file.readAsBytes();
            break;
          }
        }
      }

      if (apkBytes == null || apkBytes.isEmpty) {
        request.response.statusCode = HttpStatus.notFound;
        request.response.headers.contentType = ContentType.text;
        request.response.write('Error: OnePlusTvCompanion.apk not found on device.');
        await request.response.close();
        return;
      }

      request.response.statusCode = HttpStatus.ok;
      request.response.headers.set(
        HttpHeaders.contentTypeHeader,
        'application/vnd.android.package-archive',
      );
      request.response.headers.set(
        'content-disposition',
        'attachment; filename="OnePlusTvCompanion.apk"',
      );
      request.response.headers.set(
        HttpHeaders.contentLengthHeader,
        apkBytes.length.toString(),
      );

      request.response.add(apkBytes);
      await request.response.close();
      _log('✅ Successfully served OnePlusTvCompanion.apk (${apkBytes.length} bytes)');
    } catch (e) {
      _log('Error serving APK: $e');
      request.response.statusCode = HttpStatus.internalServerError;
      request.response.write('Internal server error');
      await request.response.close();
    }
  }

  void _serveLandingPage(HttpRequest request) {
    request.response.statusCode = HttpStatus.ok;
    request.response.headers.contentType = ContentType.html;

    final html = '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>OnePlus TV Companion Download</title>
  <style>
    body {
      background-color: #0d0d12;
      color: #ffffff;
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
      margin: 0;
      padding: 24px;
      box-sizing: border-box;
      text-align: center;
    }
    .card {
      background: #181822;
      border: 1px solid #2a2a38;
      border-radius: 20px;
      padding: 36px 32px;
      max-width: 480px;
      width: 100%;
      box-shadow: 0 16px 40px rgba(0, 0, 0, 0.6);
    }
    .badge {
      display: inline-block;
      background: #eb0028;
      color: white;
      font-weight: 800;
      font-size: 13px;
      padding: 4px 10px;
      border-radius: 6px;
      margin-bottom: 16px;
    }
    h1 {
      font-size: 24px;
      margin: 0 0 10px;
      font-weight: 700;
    }
    p {
      color: #a0a0b2;
      font-size: 14px;
      line-height: 1.5;
      margin: 0 0 28px;
    }
    .btn {
      display: block;
      background: #eb0028;
      color: white;
      text-decoration: none;
      font-size: 16px;
      font-weight: bold;
      padding: 16px 24px;
      border-radius: 12px;
      transition: background 0.2s;
    }
    .btn:hover {
      background: #c50022;
    }
    .steps {
      margin-top: 28px;
      text-align: left;
      background: #111118;
      padding: 16px 20px;
      border-radius: 12px;
      font-size: 13px;
      color: #cccccc;
      line-height: 1.6;
    }
    .steps b {
      color: #ffffff;
    }
  </style>
</head>
<body>
  <div class="card">
    <div class="badge">1+ REMOTE</div>
    <h1>OnePlus TV Companion</h1>
    <p>Install the accessibility companion service directly on your OnePlus / Android TV.</p>
    <a href="/download" class="btn">📥 Download Companion APK</a>
    <div class="steps">
      <b>Next Steps on your TV:</b><br>
      1. Click download above.<br>
      2. Open downloaded APK and tap <b>Install</b>.<br>
      3. In TV <i>Settings &rarr; Device Preferences &rarr; Accessibility</i>, turn ON <b>OnePlus TV Companion</b>.
    </div>
  </div>
</body>
</html>
''';

    request.response.write(html);
    request.response.close();
  }

  @override
  void dispose() {
    stop();
    _logController.close();
    super.dispose();
  }
}
