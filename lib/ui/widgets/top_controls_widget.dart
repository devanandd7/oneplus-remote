import 'package:flutter/material.dart';
import '../../models/remote_key.dart';
import '../../models/connection_mode.dart';
import '../../services/remote_controller.dart';
import '../../utils/constants.dart';

class TopControlsWidget extends StatelessWidget {
  final RemoteController controller;
  final VoidCallback onOpenDiscovery;

  const TopControlsWidget({
    Key? key,
    required this.controller,
    required this.onOpenDiscovery,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Mode Switcher Header (Wi-Fi / Bluetooth)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Engine Toggle Pill
            Container(
              decoration: BoxDecoration(
                color: AppColors.buttonDark,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.buttonBorder, width: 1),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  _buildModeTab(
                    title: 'Wi-Fi',
                    icon: Icons.wifi,
                    isSelected: controller.currentMode == RemoteEngineMode.wifi,
                    onTap: () => controller.switchMode(RemoteEngineMode.wifi),
                  ),
                  const SizedBox(width: 4),
                  _buildModeTab(
                    title: 'Bluetooth',
                    icon: Icons.bluetooth,
                    isSelected: controller.currentMode == RemoteEngineMode.bluetooth,
                    onTap: () => controller.switchMode(RemoteEngineMode.bluetooth),
                  ),
                ],
              ),
            ),

            // Device / Network Selector
            InkWell(
              onTap: onOpenDiscovery,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.buttonDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.buttonBorder, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildStatusDot(controller.status),
                    const SizedBox(width: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 110),
                      child: Text(
                        controller.connectedTitle,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_down, color: Colors.white54, size: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),

        // Remote Physical Top Row: [ Power (Red) ] --- [ Mic/LED ] --- [ Mute ]
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Power Button
            _buildCircularButton(
              icon: Icons.power_settings_new,
              iconColor: AppColors.onePlusRed,
              borderColor: AppColors.onePlusRed.withValues(alpha: 0.4),
              glowColor: AppColors.powerButtonGlow,
              onTap: () => controller.sendKey(RemoteKey.power),
              tooltip: 'Power',
            ),

            // Microphone Pinhole / Status LED
            Column(
              children: [
                Container(
                  width: 7,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.white12, width: 1),
                  ),
                  child: Center(
                    child: Container(
                      width: 3.5,
                      height: 3.5,
                      decoration: BoxDecoration(
                        color: controller.status == ConnectionStatus.connected
                            ? AppColors.statusConnected
                            : controller.status == ConnectionStatus.connecting
                                ? AppColors.statusConnecting
                                : Colors.white24,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Mute Button
            _buildCircularButton(
              icon: Icons.volume_off,
              iconColor: Colors.white70,
              borderColor: AppColors.buttonBorder,
              onTap: () => controller.sendKey(RemoteKey.mute),
              tooltip: 'Mute',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModeTab({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.onePlusRed : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: isSelected ? Colors.white : Colors.white54),
            const SizedBox(width: 4),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white54,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircularButton({
    required IconData icon,
    required Color iconColor,
    required Color borderColor,
    Color? glowColor,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      splashColor: iconColor.withValues(alpha: 0.3),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.buttonDark,
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: glowColor != null
              ? [
                  BoxShadow(
                    color: glowColor,
                    blurRadius: 10,
                    spreadRadius: 1,
                  )
                ]
              : [
                  const BoxShadow(
                    color: Colors.black45,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
        ),
        child: Icon(icon, color: iconColor, size: 26),
      ),
    );
  }

  Widget _buildStatusDot(ConnectionStatus status) {
    Color color;
    switch (status) {
      case ConnectionStatus.connected:
        color = AppColors.statusConnected;
        break;
      case ConnectionStatus.connecting:
      case ConnectionStatus.scanning:
        color = AppColors.statusConnecting;
        break;
      case ConnectionStatus.pairingRequired:
        color = AppColors.onePlusRed;
        break;
      default:
        color = AppColors.statusDisconnected;
    }
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.5),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}
