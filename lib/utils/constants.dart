import 'package:flutter/material.dart';

class AppColors {
  // Remote Chassis & Body
  static const Color background = Color(0xFF0F1012);
  static const Color remoteBody = Color(0xFF17181A);
  static const Color remoteBevel = Color(0xFF222428);
  static const Color remoteInnerPill = Color(0xFF1B1C1F);

  // Button Surfaces
  static const Color buttonDark = Color(0xFF24262B);
  static const Color buttonDarkPressed = Color(0xFF32353B);
  static const Color buttonBorder = Color(0xFF2D3036);

  // OnePlus Signature Colors
  static const Color onePlusRed = Color(0xFFEB0029);
  static const Color powerButtonGlow = Color(0x66EB0029);

  // Status & Accents
  static const Color statusConnected = Color(0xFF00E676);
  static const Color statusConnecting = Color(0xFFFFB300);
  static const Color statusDisconnected = Color(0xFF757575);
  static const Color activeMode = Color(0xFFEB0029);

  // App Shortcut Specifics
  static const Color netflixBg = Colors.white;
  static const Color netflixText = Color(0xFFE50914);
  static const Color primeVideoBlue = Color(0xFF00A8E1);
  static const Color youtubeRed = Color(0xFFFF0000);

  // Google Assistant Dots
  static const Color assistantBlue = Color(0xFF4285F4);
  static const Color assistantRed = Color(0xFFEA4335);
  static const Color assistantYellow = Color(0xFFFBBC05);
  static const Color assistantGreen = Color(0xFF34A853);
}

class AppConstants {
  static const String appName = 'OnePlus TV Remote';
  static const double remoteBorderRadius = 46.0;
  static const double dpadOuterSize = 220.0;
  static const double dpadCenterSize = 88.0;
}
