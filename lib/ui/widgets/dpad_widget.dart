import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/remote_key.dart';
import '../../services/remote_controller.dart';
import '../../utils/constants.dart';
import 'tactile_button.dart';

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
        child: Material(
          color: Colors.transparent,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // UP Button
              Positioned(
                top: 8,
                child: _DirectionalTapButton(
                  icon: Icons.keyboard_arrow_up,
                  width: outerSize * 0.45,
                  height: (outerSize - centerSize) / 2 + 10,
                  onTap: () => controller.sendKey(RemoteKey.dpadUp),
                ),
              ),

              // DOWN Button
              Positioned(
                bottom: 8,
                child: _DirectionalTapButton(
                  icon: Icons.keyboard_arrow_down,
                  width: outerSize * 0.45,
                  height: (outerSize - centerSize) / 2 + 10,
                  onTap: () => controller.sendKey(RemoteKey.dpadDown),
                ),
              ),

              // LEFT Button
              Positioned(
                left: 8,
                child: _DirectionalTapButton(
                  icon: Icons.keyboard_arrow_left,
                  width: (outerSize - centerSize) / 2 + 10,
                  height: outerSize * 0.45,
                  onTap: () => controller.sendKey(RemoteKey.dpadLeft),
                ),
              ),

              // RIGHT Button
              Positioned(
                right: 8,
                child: _DirectionalTapButton(
                  icon: Icons.keyboard_arrow_right,
                  width: (outerSize - centerSize) / 2 + 10,
                  height: outerSize * 0.45,
                  onTap: () => controller.sendKey(RemoteKey.dpadRight),
                ),
              ),

              // Center OK Button
              TactileButton.circle(
                size: centerSize,
                backgroundColor: AppColors.remoteBody,
                pressedColor: AppColors.buttonDarkPressed,
                borderColor: AppColors.buttonBorder,
                borderWidth: 2,
                splashColor: AppColors.onePlusRed.withValues(alpha: 0.35),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
                onTap: () => controller.sendKey(RemoteKey.ok),
                child: const Text(
                  'OK',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DirectionalTapButton extends StatefulWidget {
  final IconData icon;
  final double width;
  final double height;
  final VoidCallback onTap;

  const _DirectionalTapButton({
    Key? key,
    required this.icon,
    required this.width,
    required this.height,
    required this.onTap,
  }) : super(key: key);

  @override
  State<_DirectionalTapButton> createState() => _DirectionalTapButtonState();
}

class _DirectionalTapButtonState extends State<_DirectionalTapButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
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
      splashColor: Colors.white24,
      highlightColor: Colors.white12,
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: Center(
          child: AnimatedScale(
            scale: _isPressed ? 0.86 : 1.0,
            duration: const Duration(milliseconds: 70),
            curve: Curves.easeOutCubic,
            child: Icon(
              widget.icon,
              color: _isPressed ? Colors.white : Colors.white70,
              size: 34,
            ),
          ),
        ),
      ),
    );
  }
}
