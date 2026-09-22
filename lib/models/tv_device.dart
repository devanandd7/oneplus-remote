class TvDevice {
  final String id;
  final String name;
  final String ipAddress;
  final int port;
  final bool isPaired;

  TvDevice({
    required this.id,
    required this.name,
    required this.ipAddress,
    this.port = 6467,
    this.isPaired = false,
  });

  TvDevice copyWith({
    String? id,
    String? name,
    String? ipAddress,
    int? port,
    bool? isPaired,
  }) {
    return TvDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      ipAddress: ipAddress ?? this.ipAddress,
      port: port ?? this.port,
      isPaired: isPaired ?? this.isPaired,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'ipAddress': ipAddress,
        'port': port,
        'isPaired': isPaired,
      };

  factory TvDevice.fromJson(Map<String, dynamic> json) => TvDevice(
        id: json['id'] as String,
        name: json['name'] as String,
        ipAddress: json['ipAddress'] as String,
        port: json['port'] as int? ?? 6467,
        isPaired: json['isPaired'] as bool? ?? false,
      );
}
