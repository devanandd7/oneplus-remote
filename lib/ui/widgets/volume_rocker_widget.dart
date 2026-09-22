import 'package:flutter/material.dart';
import '../../models/remote_key.dart';
import '../../services/remote_controller.dart';
import '../../utils/constants.dart';

class VolumeRockerWidget extends StatelessWidget {
  final RemoteController controller;

  const VolumeRockerWidget({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 260,
        height: 58,
        decoration: BoxDecoration(
          color: AppColors.buttonDark,
          borderRadius: BorderRadius.circular(29),
          border: Border.all(color: AppColors.buttonBorder, width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Volume Down (-)
            Expanded(
              child: InkWell(
                onTap: () => controller.sendKey(RemoteKey.volumeDown),
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(29)),
                splashColor: Colors.white24,
                child: const Center(
                  child: Icon(Icons.remove, color: Colors.white70, size: 28),
                ),
              ),
            ),

            // Google Assistant Center Button
            InkWell(
              onTap: () => controller.sendKey(RemoteKey.assistant),
              borderRadius: BorderRadius.circular(25),
              splashColor: AppColors.assistantBlue.withValues(alpha: 0.3),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.remoteBody,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.buttonBorder, width: 1.5),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black54,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: _buildGoogleAssistantDots(),
                ),
              ),
            ),

            // Volume Up (+)
            Expanded(
              child: InkWell(
                onTap: () => controller.sendKey(RemoteKey.volumeUp),
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(29)),
                splashColor: Colors.white24,
                child: const Center(
                  child: Icon(Icons.add, color: Colors.white70, size: 28),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleAssistantDots() {
    return SizedBox(
      width: 24,
      height: 24,
      child: Stack(
        children: [
          // Blue dot (large)
          Positioned(
            left: 2,
            top: 5,
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: AppColors.assistantBlue,
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Red dot
          Positioned(
            left: 13,
            top: 4,
            child: Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: AppColors.assistantRed,
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Yellow dot
          Positioned(
            left: 12,
            top: 11,
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.assistantYellow,
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Green dot
          Positioned(
            left: 19,
            top: 9,
            child: Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: AppColors.assistantGreen,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
