import 'package:flutter/material.dart';
import '../../models/remote_key.dart';
import '../../services/remote_controller.dart';
import '../../utils/constants.dart';
import 'tactile_button.dart';
import 'custom_macros_widget.dart';
import 'keyboard_sheet.dart';

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
        // App Shortcuts Row: [ Keyboard ] on Left, [ MENU ] on Right
        Row(
          children: [
            // Left: Keyboard Button
            Expanded(
              child: TactileButton.pill(
                height: 48,
                backgroundColor: AppColors.buttonDark,
                borderColor: AppColors.buttonBorder,
                splashColor: AppColors.onePlusRed.withValues(alpha: 0.25),
                tooltip: 'TV Keyboard: Type text & search on TV',
                onTap: () {
                  KeyboardSheet.show(context, controller);
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.keyboard, color: AppColors.onePlusRed, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Keyboard',
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
        const SizedBox(height: 12),

        // Smart HDMI Switcher Row: [ HDMI 1 ] & [ HDMI 2 ]
        Row(
          children: [
            Expanded(
              child: TactileButton.pill(
                height: 44,
                backgroundColor: AppColors.buttonDark,
                borderColor: AppColors.buttonBorder,
                splashColor: Colors.blueAccent.withValues(alpha: 0.25),
                tooltip: 'Smart Switch to HDMI 1 (Ceiling Reset)',
                onTap: () => controller.switchHdmiInput(1),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.settings_input_hdmi, color: Colors.blueAccent, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'HDMI 1',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: TactileButton.pill(
                height: 44,
                backgroundColor: AppColors.buttonDark,
                borderColor: AppColors.buttonBorder,
                splashColor: Colors.purpleAccent.withValues(alpha: 0.25),
                tooltip: 'Smart Switch to HDMI 2 (Ceiling Reset)',
                onTap: () => controller.switchHdmiInput(2),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.settings_input_hdmi, color: Colors.purpleAccent, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'HDMI 2',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Custom Buttons & Step Recording Section
        CustomMacrosWidget(controller: controller),
      ],
    );
  }
}
