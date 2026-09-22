import 'package:flutter/material.dart';
import '../../services/remote_controller.dart';
import '../../utils/constants.dart';

class PairingDialog extends StatefulWidget {
  final RemoteController controller;

  const PairingDialog({Key? key, required this.controller}) : super(key: key);

  static Future<void> show(BuildContext context, RemoteController controller) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PairingDialog(controller: controller),
    );
  }

  @override
  State<PairingDialog> createState() => _PairingDialogState();
}

class _PairingDialogState extends State<PairingDialog> {
  final TextEditingController _pinController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _submitPin() async {
    final pin = _pinController.text.trim();
    if (pin.length < 4) {
      setState(() {
        _errorMessage = 'Please enter the code displayed on your OnePlus TV';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final success = await widget.controller.submitWifiPin(pin);

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });

      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully paired with OnePlus TV!'),
            backgroundColor: AppColors.statusConnected,
          ),
        );
      } else {
        setState(() {
          _errorMessage = 'Invalid PIN or pairing timed out. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.remoteBody,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.buttonBorder, width: 1.5),
      ),
      title: Row(
        children: const [
          Icon(Icons.tv, color: AppColors.onePlusRed, size: 28),
          SizedBox(width: 10),
          Text(
            'Pair with TV',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Check your OnePlus TV screen for a pairing code (usually 6 letters/digits):',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _pinController,
            autofocus: true,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              letterSpacing: 4,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: 'Enter PIN',
              hintStyle: const TextStyle(color: Colors.white30, letterSpacing: 1),
              fillColor: AppColors.buttonDark,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.buttonBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.onePlusRed, width: 2),
              ),
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 10),
            Text(
              _errorMessage!,
              style: const TextStyle(color: AppColors.onePlusRed, fontSize: 12),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
        ),
        TextButton(
          onPressed: () async {
            Navigator.of(context).pop();
            final device = widget.controller.selectedTv;
            if (device != null) {
              await widget.controller.connectWifiTv(device);
            }
          },
          child: const Text('Direct Connect', style: TextStyle(color: AppColors.assistantBlue)),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitPin,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.onePlusRed,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Submit PIN', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
