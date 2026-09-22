import 'remote_key.dart';

class MacroStep {
  final RemoteKey key;
  final int delayMs;

  const MacroStep({
    required this.key,
    this.delayMs = 1000,
  });

  Map<String, dynamic> toJson() => {
    'key': key.name,
    'delayMs': delayMs,
  };

  factory MacroStep.fromJson(Map<String, dynamic> json) {
    return MacroStep(
      key: RemoteKey.values.firstWhere(
        (k) => k.name == json['key'],
        orElse: () => RemoteKey.ok,
      ),
      delayMs: json['delayMs'] as int? ?? 1000,
    );
  }
}

class MacroButton {
  final String id;
  final String title;
  final int iconCodePoint;
  final int colorValue;
  final List<MacroStep> steps;

  const MacroButton({
    required this.id,
    required this.title,
    required this.iconCodePoint,
    required this.colorValue,
    required this.steps,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'iconCodePoint': iconCodePoint,
    'colorValue': colorValue,
    'steps': steps.map((s) => s.toJson()).toList(),
  };

  factory MacroButton.fromJson(Map<String, dynamic> json) {
    return MacroButton(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title'] as String? ?? 'Custom Button',
      iconCodePoint: json['iconCodePoint'] as int? ?? 0xe57f, // Icons.touch_app
      colorValue: json['colorValue'] as int? ?? 0xFFEB0029, // OnePlus Red
      steps: (json['steps'] as List<dynamic>? ?? [])
          .map((s) => MacroStep.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}
