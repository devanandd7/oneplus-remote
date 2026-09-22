import 'package:flutter/services.dart';

class HapticService {
  static void buttonClick() {
    HapticFeedback.lightImpact();
  }

  static void powerClick() {
    HapticFeedback.heavyImpact();
  }

  static void navigationClick() {
    HapticFeedback.selectionClick();
  }
}
