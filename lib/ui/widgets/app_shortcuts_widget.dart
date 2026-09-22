import 'package:flutter/material.dart';
import '../../models/remote_key.dart';
import '../../services/remote_controller.dart';
import '../../utils/constants.dart';
import 'tactile_button.dart';
import 'custom_macros_widget.dart';

class AppShortcutsWidget extends StatelessWidget {
  final RemoteController controller;

  const AppShortcutsWidget({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // App Shortcuts Row: [ YouTube ] on Left, [ MENU ] on Right
        Row(
          children: [
            // Left: YouTube Button
            Expanded(
              child: TactileButton.pill(
                height: 48,
                backgroundColor: AppColors.buttonDark,
                borderColor: AppColors.buttonBorder,
                splashColor: AppColors.youtubeRed.withValues(alpha: 0.25),
                onTap: () => controller.sendKey(RemoteKey.youtube),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.play_arrow, color: AppColors.youtubeRed, size: 22),
                    SizedBox(width: 6),
                    Text(
                      'YouTube',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Right: MENU Button
            Expanded(
              child: TactileButton.pill(
                height: 48,
                backgroundColor: AppColors.buttonDark,
                borderColor: AppColors.buttonBorder,
                onTap: () => controller.sendKey(RemoteKey.menu),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.menu, color: Colors.white70, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'MENU',
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Custom Buttons & Step Recording Section
        CustomMacrosWidget(controller: controller),
      ],
    );
  }
}
