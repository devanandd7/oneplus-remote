import 'package:flutter/material.dart';
import '../../services/remote_controller.dart';
import '../../utils/constants.dart';
import 'tactile_button.dart';

class MacroRecordingBanner extends StatelessWidget {
  final RemoteController controller;
  final VoidCallback onSavePressed;

  const MacroRecordingBanner({
    Key? key,
    required this.controller,
    required this.onSavePressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!controller.isRecordingMacro && !controller.isPlayingMacro) {
      return const SizedBox.shrink();
    }

    if (controller.isPlayingMacro) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF10281F),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.statusConnected, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.statusConnected.withValues(alpha: 0.25),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.statusConnected),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Replaying: ${controller.playingMacroTitle ?? "Custom Action"}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    controller.playbackStatusMessage.isNotEmpty
                        ? controller.playbackStatusMessage
                        : 'Executing step ${controller.playingStepIndex}...',
                    style: const TextStyle(
                      color: AppColors.statusConnected,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white70, size: 20),
              onPressed: () => controller.stopMacroPlayback(),
              tooltip: 'Stop Replay',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      );
    }

    // Recording Mode Banner
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF241014),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.onePlusRed, width: 1.8),
        boxShadow: [
          BoxShadow(
            color: AppColors.onePlusRed.withValues(alpha: 0.35),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Live pulse dot + title + Cancel
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.onePlusRed,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'RECORDING BUTTON STEPS',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: controller.cancelMacroRecording,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.close, color: Colors.white60, size: 16),
                      SizedBox(width: 2),
                      Text(
                        'Cancel',
                        style: TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          const Text(
            'Press any buttons on remote. Steps are being recorded:',
            style: TextStyle(color: Colors.white70, fontSize: 11),
          ),
          const SizedBox(height: 10),

          // Steps list horizontal scroll
          SizedBox(
            height: 32,
            child: controller.recordedSteps.isEmpty
                ? const Text(
                    'No steps recorded yet...',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  )
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: controller.recordedSteps.length,
                    separatorBuilder: (_, __) => const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(Icons.chevron_right, color: Colors.white38, size: 16),
                    ),
                    itemBuilder: (context, index) {
                      final stepKey = controller.recordedSteps[index];
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: index == 0 ? AppColors.onePlusRed : const Color(0xFF381B20),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: index == 0 ? Colors.transparent : Colors.white24,
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            stepKey.name.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 12),

          // Action: Finish & Save Button
          SizedBox(
            width: double.infinity,
            child: TactileButton.pill(
              height: 42,
              backgroundColor: AppColors.onePlusRed,
              borderColor: Colors.white30,
              onTap: onSavePressed,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Done & Save (${controller.recordedSteps.length} Steps)',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
