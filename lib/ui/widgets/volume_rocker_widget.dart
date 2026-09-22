import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/remote_key.dart';
import '../../services/remote_controller.dart';
import '../../utils/constants.dart';
import 'tactile_button.dart';

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
        child: Material(
          color: Colors.transparent,
          child: Row(
            children: [
              // Volume Down (-)
              Expanded(
                child: _VolumeRockerButton(
                  icon: Icons.remove,
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(29)),
                  onTap: () => controller.sendKey(RemoteKey.volumeDown),
                ),
              ),

              // Google Assistant Center Button
              TactileButton.circle(
                size: 50,
                backgroundColor: AppColors.remoteBody,
                borderColor: AppColors.buttonBorder,
                splashColor: AppColors.assistantBlue.withValues(alpha: 0.35),
                onTap: () => controller.sendKey(RemoteKey.assistant),
                tooltip: 'Google Assistant',
                child: _buildGoogleAssistantDots(),
              ),

              // Volume Up (+)
              Expanded(
                child: _VolumeRockerButton(
                  icon: Icons.add,
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(29)),
                  onTap: () => controller.sendKey(RemoteKey.volumeUp),
                ),
              ),
            ],
          ),
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

class _VolumeRockerButton extends StatefulWidget {
  final IconData icon;
  final BorderRadius borderRadius;
  final VoidCallback onTap;

  const _VolumeRockerButton({
    Key? key,
    required this.icon,
    required this.borderRadius,
    required this.onTap,
  }) : super(key: key);

  @override
  State<_VolumeRockerButton> createState() => _VolumeRockerButtonState();
}

class _VolumeRockerButtonState extends State<_VolumeRockerButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      decoration: BoxDecoration(
        color: _isPressed ? AppColors.buttonDarkPressed : Colors.transparent,
        borderRadius: widget.borderRadius,
      ),
      child: InkWell(
        onTapDown: (_) {
          setState(() => _isPressed = true);
          HapticFeedback.lightImpact();
        },
        onTapUp: (_) {
          if (_isPressed) setState(() => _isPressed = false);
        },
        onTapCancel: () {
          if (_isPressed) setState(() => _isPressed = false);
        },
        onTap: widget.onTap,
        borderRadius: widget.borderRadius,
        splashColor: Colors.white24,
        highlightColor: Colors.white12,
        child: Center(
          child: AnimatedScale(
            scale: _isPressed ? 0.88 : 1.0,
            duration: const Duration(milliseconds: 80),
            curve: Curves.easeOutCubic,
            child: Icon(
              widget.icon,
              color: _isPressed ? Colors.white : Colors.white70,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}

