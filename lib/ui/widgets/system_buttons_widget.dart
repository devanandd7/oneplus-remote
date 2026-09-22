import 'package:flutter/material.dart';
import '../../models/remote_key.dart';
import '../../services/remote_controller.dart';
import '../../utils/constants.dart';

class SystemButtonsWidget extends StatelessWidget {
  final RemoteController controller;

  const SystemButtonsWidget({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back Button (←)
          _buildCircularSystemButton(
            icon: Icons.arrow_back,
            onTap: () => controller.sendKey(RemoteKey.back),
            tooltip: 'Back',
          ),

          // Home Button (O)
          _buildCircularSystemButton(
            customIcon: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white70, width: 2.5),
              ),
            ),
            onTap: () => controller.sendKey(RemoteKey.home),
            tooltip: 'Home',
          ),
        ],
      ),
    );
  }

  Widget _buildCircularSystemButton({
    IconData? icon,
    Widget? customIcon,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      splashColor: Colors.white24,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.buttonDark,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.buttonBorder, width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Colors.black45,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: customIcon ?? Icon(icon, color: Colors.white70, size: 24),
        ),
      ),
    );
  }
}
