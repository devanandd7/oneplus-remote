enum RemoteEngineMode {
  wifi,
  bluetooth,
}

enum ConnectionStatus {
  disconnected,
  scanning,
  connecting,
  pairingRequired,
  connected,
  error,
}

extension ConnectionStatusExtension on ConnectionStatus {
  String get displayName {
    switch (this) {
      case ConnectionStatus.disconnected:
        return 'Disconnected';
      case ConnectionStatus.scanning:
        return 'Scanning TVs...';
      case ConnectionStatus.connecting:
        return 'Connecting...';
      case ConnectionStatus.pairingRequired:
        return 'Pairing Required (Enter PIN)';
      case ConnectionStatus.connected:
        return 'Connected';
      case ConnectionStatus.error:
        return 'Connection Error';
    }
  }
}
