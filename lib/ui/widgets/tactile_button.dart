import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/constants.dart';

/// A premium, tactile interactive button that provides:
/// 1. Micro-scale compression animation on press (feels like a physical button click).
/// 2. Instant visual highlight feedback on tap.
/// 3. Native Material Ink ripple that renders cleanly on dark button surfaces.
/// 4. Tactile haptic feedback on touch down.
class TactileButton extends StatefulWidget {
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Widget child;
  final double? width;
  final double? height;
  final Color? backgroundColor;
  final Color? pressedColor;
  final Color? borderColor;
  final double borderWidth;
  final BorderRadius? borderRadius;
  final BoxShape shape;
  final List<BoxShadow>? boxShadow;
  final Color? splashColor;
  final Color? highlightColor;
  final String? tooltip;
  final EdgeInsetsGeometry? padding;
  final double pressedScale;

  const TactileButton({
    Key? key,
    required this.onTap,
    required this.child,
    this.onLongPress,
    this.width,
    this.height,
    this.backgroundColor,
    this.pressedColor,
    this.borderColor,
    this.borderWidth = 1.5,
    this.borderRadius,
    this.shape = BoxShape.rectangle,
    this.boxShadow,
    this.splashColor,
    this.highlightColor,
    this.tooltip,
    this.padding,
    this.pressedScale = 0.93,
  }) : super(key: key);

  /// Circular tactile button helper
  factory TactileButton.circle({
    Key? key,
    required double size,
    required VoidCallback? onTap,
    required Widget child,
    VoidCallback? onLongPress,
    Color? backgroundColor,
    Color? pressedColor,
    Color? borderColor,
    double borderWidth = 1.5,
    List<BoxShadow>? boxShadow,
    Color? splashColor,
    Color? highlightColor,
    String? tooltip,
    double pressedScale = 0.92,
  }) {
    return TactileButton(
      key: key,
      width: size,
      height: size,
      shape: BoxShape.circle,
      onTap: onTap,
      onLongPress: onLongPress,
      backgroundColor: backgroundColor ?? AppColors.buttonDark,
      pressedColor: pressedColor ?? AppColors.buttonDarkPressed,
      borderColor: borderColor ?? AppColors.buttonBorder,
      borderWidth: borderWidth,
      boxShadow: boxShadow,
      splashColor: splashColor,
      highlightColor: highlightColor,
      tooltip: tooltip,
      pressedScale: pressedScale,
      child: child,
    );
  }

  /// Pill-shaped tactile button helper
  factory TactileButton.pill({
    Key? key,
    required double height,
    required VoidCallback? onTap,
    required Widget child,
    double? width,
    VoidCallback? onLongPress,
    Color? backgroundColor,
    Color? pressedColor,
    Color? borderColor,
    double borderWidth = 1.5,
    double radius = 24.0,
    List<BoxShadow>? boxShadow,
    Color? splashColor,
    Color? highlightColor,
    String? tooltip,
    EdgeInsetsGeometry? padding,
    double pressedScale = 0.94,
  }) {
    return TactileButton(
      key: key,
      width: width,
      height: height,
      shape: BoxShape.rectangle,
      borderRadius: BorderRadius.circular(radius),
      onTap: onTap,
      onLongPress: onLongPress,
      backgroundColor: backgroundColor ?? AppColors.buttonDark,
      pressedColor: pressedColor ?? AppColors.buttonDarkPressed,
      borderColor: borderColor ?? AppColors.buttonBorder,
      borderWidth: borderWidth,
      boxShadow: boxShadow,
      splashColor: splashColor,
      highlightColor: highlightColor,
      tooltip: tooltip,
      padding: padding,
      pressedScale: pressedScale,
      child: child,
    );
  }

  @override
  State<TactileButton> createState() => _TactileButtonState();
}

class _TactileButtonState extends State<TactileButton> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails _) {
    if (widget.onTap == null && widget.onLongPress == null) return;
    setState(() => _isPressed = true);
    HapticFeedback.lightImpact();
  }

  void _handleTapUp(TapUpDetails _) {
    if (_isPressed) {
      setState(() => _isPressed = false);
    }
  }

  void _handleTapCancel() {
    if (_isPressed) {
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveBg = widget.backgroundColor ?? AppColors.buttonDark;
    final effectivePressedBg = widget.pressedColor ?? AppColors.buttonDarkPressed;
    final effectiveBorder = widget.borderColor ?? AppColors.buttonBorder;

    final isCircle = widget.shape == BoxShape.circle;
    final borderRad = isCircle
        ? null
        : (widget.borderRadius ?? BorderRadius.circular(16));

    final effectiveSplash = widget.splashColor ?? Colors.white.withValues(alpha: 0.22);
    final effectiveHighlight = widget.highlightColor ?? Colors.white.withValues(alpha: 0.12);

    Widget buttonContent = AnimatedScale(
      scale: _isPressed ? widget.pressedScale : 1.0,
      duration: Duration(milliseconds: _isPressed ? 70 : 160),
      curve: _isPressed ? Curves.easeOutQuad : Curves.easeOutBack,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: widget.width,
        height: widget.height,
        padding: widget.padding,
        decoration: BoxDecoration(
          color: _isPressed ? effectivePressedBg : effectiveBg,
          shape: widget.shape,
          borderRadius: borderRad,
          border: Border.all(
            color: _isPressed ? effectiveBorder.withValues(alpha: 0.9) : effectiveBorder,
            width: widget.borderWidth,
          ),
          boxShadow: _isPressed
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ]
              : (widget.boxShadow ??
                  [
                    const BoxShadow(
                      color: Colors.black45,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ]),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            customBorder: isCircle ? const CircleBorder() : RoundedRectangleBorder(borderRadius: borderRad!),
            splashColor: effectiveSplash,
            highlightColor: effectiveHighlight,
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            onTap: widget.onTap,
            onLongPress: widget.onLongPress,
            child: Center(
              child: widget.child,
            ),
          ),
        ),
      ),
    );

    if (widget.tooltip != null && widget.tooltip!.isNotEmpty) {
      buttonContent = Tooltip(
        message: widget.tooltip!,
        child: buttonContent,
      );
    }

    return buttonContent;
  }
}
