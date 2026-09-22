import 'package:flutter/material.dart';
import '../../models/macro_button.dart';
import '../../services/remote_controller.dart';
import '../../utils/constants.dart';
import 'tactile_button.dart';

class CustomMacrosWidget extends StatelessWidget {
  final RemoteController controller;

  static const List<IconData> macroIcons = [
    Icons.settings,
    Icons.tune,
    Icons.tv,
    Icons.input,
    Icons.settings_input_hdmi,
    Icons.movie,
    Icons.gamepad,
    Icons.apps,
    Icons.star,
    Icons.volume_up,
    Icons.power_settings_new,
  ];

  static IconData getMacroIcon(int codePoint) {
    for (final icon in macroIcons) {
      if (icon.codePoint == codePoint) return icon;
    }
    return Icons.touch_app;
  }

  const CustomMacrosWidget({
    Key? key,
    required this.controller,
  }) : super(key: key);

  void _showDeleteDialog(BuildContext context, MacroButton macro) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.remoteBody,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.buttonBorder, width: 1.5),
        ),
        title: Row(
          children: const [
            Icon(Icons.delete_outline, color: AppColors.onePlusRed, size: 24),
            SizedBox(width: 8),
            Text(
              'Delete Shortcut?',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${macro.title}" (${macro.steps.length} steps)?',
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.onePlusRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              controller.deleteMacro(macro.id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  static void showSaveMacroDialog(BuildContext context, RemoteController controller) {
    final titleController = TextEditingController(text: 'My Shortcut');
    int selectedIconCode = Icons.settings.codePoint;
    int selectedColor = AppColors.onePlusRed.toARGB32();

    final availableColors = [
      AppColors.onePlusRed,
      const Color(0xFF2196F3), // Blue
      const Color(0xFF00E676), // Green
      const Color(0xFFFF9800), // Orange
      const Color(0xFF9C27B0), // Purple
      const Color(0xFF00BCD4), // Cyan
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: const BoxDecoration(
              color: AppColors.remoteBody,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(top: BorderSide(color: AppColors.buttonBorder, width: 2)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Save Custom Button',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.onePlusRed.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${controller.recordedSteps.length} Steps Recorded',
                        style: const TextStyle(
                          color: AppColors.onePlusRed,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Button Name Input
                const Text(
                  'Button Name',
                  style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: titleController,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'e.g. TV Settings, HDMI 2, Picture Mode',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: AppColors.buttonDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.buttonBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.onePlusRed, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Select Icon
                const Text(
                  'Select Icon',
                  style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 48,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: macroIcons.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, i) {
                      final ic = macroIcons[i];
                      final isSelected = ic.codePoint == selectedIconCode;
                      return GestureDetector(
                        onTap: () {
                          setModalState(() => selectedIconCode = ic.codePoint);
                        },
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.onePlusRed : AppColors.buttonDark,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? Colors.white : AppColors.buttonBorder,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Icon(ic, color: isSelected ? Colors.white : Colors.white70, size: 24),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 18),

                // Select Color
                const Text(
                  'Accent Color',
                  style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Row(
                  children: availableColors.map((col) {
                    final isSelected = col.toARGB32() == selectedColor;
                    return GestureDetector(
                      onTap: () {
                        setModalState(() => selectedColor = col.toARGB32());
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: col,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.transparent,
                            width: 2.5,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: col.withValues(alpha: 0.5),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  )
                                ]
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white, size: 18)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Save Action Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.onePlusRed,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                    ),
                    onPressed: () {
                      final name = titleController.text.trim();
                      controller.saveMacro(
                        title: name.isEmpty ? 'Custom Shortcut' : name,
                        iconCodePoint: selectedIconCode,
                        colorValue: selectedColor,
                      );
                      Navigator.pop(ctx);
                    },
                    child: const Text(
                      'Save & Add to Remote',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'CUSTOM SHORTCUTS',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                'Long-press to delete',
                style: TextStyle(
                  color: Colors.white30,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Display saved custom buttons above
        if (controller.customMacros.isNotEmpty) ...[
          Column(
            children: controller.customMacros.map((macro) {
              final buttonColor = Color(macro.colorValue);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TactileButton.pill(
                  height: 52,
                  backgroundColor: AppColors.buttonDark,
                  borderColor: buttonColor.withValues(alpha: 0.5),
                  splashColor: buttonColor.withValues(alpha: 0.25),
                  onTap: () => controller.playMacro(macro),
                  onLongPress: () => _showDeleteDialog(context, macro),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: buttonColor.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          getMacroIcon(macro.iconCodePoint),
                          color: buttonColor,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              macro.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${macro.steps.length} automated steps',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.play_circle_fill_rounded, color: Colors.white38, size: 22),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 4),
        ],

        // Full-Width "+ Record Custom Button"
        TactileButton.pill(
          height: 48,
          backgroundColor: const Color(0xFF1B1D22),
          borderColor: AppColors.onePlusRed.withValues(alpha: 0.6),
          splashColor: AppColors.onePlusRed.withValues(alpha: 0.2),
          onTap: () {
            if (controller.isRecordingMacro) {
              showSaveMacroDialog(context, controller);
            } else {
              controller.startMacroRecording();
            }
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: controller.isRecordingMacro ? Colors.amber : AppColors.onePlusRed,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                controller.isRecordingMacro ? 'Finish & Save Recording' : '+ Record Custom Button',
                style: TextStyle(
                  color: controller.isRecordingMacro ? Colors.amber : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
