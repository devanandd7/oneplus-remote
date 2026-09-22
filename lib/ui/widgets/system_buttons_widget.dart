import 'package:flutter/material.dart';
import '../../models/remote_key.dart';
import '../../services/remote_controller.dart';
import 'tactile_button.dart';

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
          TactileButton.circle(
            size: 56,
            onTap: () => controller.sendKey(RemoteKey.back),
            tooltip: 'Back',
            child: const Icon(Icons.arrow_back, color: Colors.white70, size: 24),
          ),

          // Home Button (O)
          TactileButton.circle(
            size: 56,
            onTap: () => controller.sendKey(RemoteKey.home),
            tooltip: 'Home',
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white70, width: 2.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
