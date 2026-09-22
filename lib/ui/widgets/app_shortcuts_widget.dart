import 'package:flutter/material.dart';
import '../../models/remote_key.dart';
import '../../services/remote_controller.dart';
import '../../utils/constants.dart';

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
        // Row 1: [ NETFLIX ] and [ MENU ]
        Row(
          children: [
            Expanded(
              child: _buildPillButton(
                backgroundColor: AppColors.netflixBg,
                borderColor: Colors.white,
                onTap: () => controller.sendKey(RemoteKey.netflix),
                child: const Text(
                  'NETFLIX',
                  style: TextStyle(
                    color: AppColors.netflixText,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildPillButton(
                backgroundColor: AppColors.buttonDark,
                borderColor: AppColors.buttonBorder,
                onTap: () => controller.sendKey(RemoteKey.menu),
                child: const Text(
                  'MENU',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Row 2: [ prime video ] and [ YouTube ]
        Row(
          children: [
            Expanded(
              child: _buildPillButton(
                backgroundColor: AppColors.buttonDark,
                borderColor: AppColors.buttonBorder,
                onTap: () => controller.sendKey(RemoteKey.primeVideo),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      'prime video',
                      style: TextStyle(
                        color: AppColors.primeVideoBlue,
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
              child: _buildPillButton(
                backgroundColor: AppColors.buttonDark,
                borderColor: AppColors.buttonBorder,
                onTap: () => controller.sendKey(RemoteKey.youtube),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.play_arrow, color: AppColors.youtubeRed, size: 20),
                    SizedBox(width: 4),
                    Text(
                      'YouTube',
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
      ],
    );
  }

  Widget _buildPillButton({
    required Color backgroundColor,
    required Color borderColor,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Colors.black45,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }
}
