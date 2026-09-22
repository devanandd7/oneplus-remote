import 'package:flutter/material.dart';
import '../../models/remote_key.dart';
import '../../services/remote_controller.dart';
import '../../utils/constants.dart';

class DpadWidget extends StatelessWidget {
  final RemoteController controller;

  const DpadWidget({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const double outerSize = AppConstants.dpadOuterSize;
    const double centerSize = AppConstants.dpadCenterSize;

    return Center(
      child: Container(
        width: outerSize,
        height: outerSize,
        decoration: BoxDecoration(
          color: AppColors.buttonDark,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.buttonBorder, width: 2),
          boxShadow: const [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
            BoxShadow(
              color: Color(0x22FFFFFF),
              blurRadius: 1,
              offset: Offset(0, -1),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // UP Button
            Positioned(
              top: 8,
              child: _buildDirectionButton(
                icon: Icons.keyboard_arrow_up,
                keyToPress: RemoteKey.dpadUp,
                width: outerSize * 0.45,
                height: (outerSize - centerSize) / 2 + 10,
              ),
            ),

            // DOWN Button
            Positioned(
              bottom: 8,
              child: _buildDirectionButton(
                icon: Icons.keyboard_arrow_down,
                keyToPress: RemoteKey.dpadDown,
                width: outerSize * 0.45,
                height: (outerSize - centerSize) / 2 + 10,
              ),
            ),

            // LEFT Button
            Positioned(
              left: 8,
              child: _buildDirectionButton(
                icon: Icons.keyboard_arrow_left,
                keyToPress: RemoteKey.dpadLeft,
                width: (outerSize - centerSize) / 2 + 10,
                height: outerSize * 0.45,
              ),
            ),

            // RIGHT Button
            Positioned(
              right: 8,
              child: _buildDirectionButton(
                icon: Icons.keyboard_arrow_right,
                keyToPress: RemoteKey.dpadRight,
                width: (outerSize - centerSize) / 2 + 10,
                height: outerSize * 0.45,
              ),
            ),

            // Center OK Button
            InkWell(
              onTap: () => controller.sendKey(RemoteKey.ok),
              borderRadius: BorderRadius.circular(centerSize / 2),
              splashColor: AppColors.onePlusRed.withValues(alpha: 0.3),
              child: Container(
                width: centerSize,
                height: centerSize,
                decoration: BoxDecoration(
                  color: AppColors.remoteBody,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.buttonBorder, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black54,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'OK',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDirectionButton({
    required IconData icon,
    required RemoteKey keyToPress,
    required double width,
    required double height,
  }) {
    return InkWell(
      onTap: () => controller.sendKey(keyToPress),
      splashColor: Colors.white24,
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        width: width,
        height: height,
        child: Center(
          child: Icon(icon, color: Colors.white70, size: 34),
        ),
      ),
    );
  }
}
