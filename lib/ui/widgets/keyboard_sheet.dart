import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/remote_key.dart';
import '../../services/remote_controller.dart';
import '../../utils/constants.dart';

class KeyboardSheet extends StatefulWidget {
  final RemoteController controller;

  const KeyboardSheet({
    Key? key,
    required this.controller,
  }) : super(key: key);

  static void show(BuildContext context, RemoteController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => KeyboardSheet(controller: controller),
    );
  }

  @override
  State<KeyboardSheet> createState() => _KeyboardSheetState();
}

class _KeyboardSheetState extends State<KeyboardSheet> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _previousText = '';

  @override
  void initState() {
    super.initState();
    // Auto-focus the soft keyboard after bottom sheet slide animation completes
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _sendCurrentText() async {
    final text = _textController.text;
    if (text.isEmpty) return;
    await widget.controller.sendText(text);
    _previousText = '';
    _textController.clear();
    setState(() {});
  }

  Future<void> _pasteFromClipboardAndSend() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (text.isNotEmpty) {
      _textController.text = text;
      _previousText = text;
      setState(() {});
      await widget.controller.sendText(text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pasted & sent "$text" to TV!'),
            duration: const Duration(seconds: 2),
            backgroundColor: AppColors.buttonDark,
          ),
        );
      }
    }
  }

  void _onTextChanged(String newText) {
    // If text was added character-by-character
    if (newText.length > _previousText.length) {
      final added = newText.substring(_previousText.length);
      widget.controller.sendText(added);
    } else if (newText.length < _previousText.length) {
      // Backspace pressed in mobile keyboard
      final deleteCount = _previousText.length - newText.length;
      for (int i = 0; i < deleteCount; i++) {
        widget.controller.sendBackspace();
      }
    }
    _previousText = newText;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 18,
        bottom: bottomInset + 18,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF161622),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black87,
            blurRadius: 32,
            spreadRadius: 6,
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Drag Handle
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Header: Title + Status + Close
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.onePlusRed.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.keyboard,
                        color: AppColors.onePlusRed,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Smart TV Keyboard',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Live keystroke stream & instant paste',
                          style: TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white60, size: 22),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Live Input Field
            TextField(
              controller: _textController,
              focusNode: _focusNode,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              cursorColor: AppColors.onePlusRed,
              textInputAction: TextInputAction.search,
              onChanged: _onTextChanged,
              onSubmitted: (_) {
                widget.controller.sendEnter();
              },
              decoration: InputDecoration(
                hintText: 'Type text or search on TV...',
                hintStyle: const TextStyle(color: Colors.white30, fontSize: 14),
                filled: true,
                fillColor: const Color(0xFF0D0D14),
                prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 20),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_textController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white54, size: 18),
                        onPressed: () {
                          _textController.clear();
                          _previousText = '';
                          setState(() {});
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.send_rounded, color: AppColors.onePlusRed, size: 20),
                      tooltip: 'Send remaining text',
                      onPressed: _textController.text.isNotEmpty ? _sendCurrentText : null,
                    ),
                  ],
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.white12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.onePlusRed, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Tactile Quick Action Controls Row
            Row(
              children: [
                // 1-Tap Paste & Send
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.paste_rounded, size: 16),
                    label: const Text(
                      'Paste & Send',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF222234),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      side: const BorderSide(color: Colors.white12),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _pasteFromClipboardAndSend,
                  ),
                ),
                const SizedBox(width: 8),

                // Space Key
                Expanded(
                  flex: 2,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white12),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      _textController.text += ' ';
                      _previousText = _textController.text;
                      widget.controller.sendSpace();
                    },
                    child: const Text('Space ␣', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),

                // Backspace Key
                IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF222234),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Colors.white12),
                    ),
                    padding: const EdgeInsets.all(12),
                  ),
                  tooltip: 'Backspace',
                  icon: const Icon(Icons.backspace_outlined, color: Colors.white70, size: 18),
                  onPressed: () {
                    if (_textController.text.isNotEmpty) {
                      _textController.text = _textController.text
                          .substring(0, _textController.text.length - 1);
                      _previousText = _textController.text;
                    }
                    widget.controller.sendBackspace();
                  },
                ),
                const SizedBox(width: 8),

                // Enter Key
                IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.onePlusRed,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(12),
                  ),
                  tooltip: 'Enter / Search',
                  icon: const Icon(Icons.keyboard_return_rounded, color: Colors.white, size: 20),
                  onPressed: () {
                    widget.controller.sendEnter();
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // In-Keyboard D-Pad Assist (navigate TV search results without closing sheet)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF0E0E16),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TV Navigation Assist:',
                    style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  Row(
                    children: [
                      _buildMiniNavBtn(Icons.arrow_upward, RemoteKey.dpadUp),
                      const SizedBox(width: 6),
                      _buildMiniNavBtn(Icons.arrow_downward, RemoteKey.dpadDown),
                      const SizedBox(width: 6),
                      _buildMiniNavBtn(Icons.arrow_back, RemoteKey.dpadLeft),
                      const SizedBox(width: 6),
                      _buildMiniNavBtn(Icons.arrow_forward, RemoteKey.dpadRight),
                      const SizedBox(width: 6),
                      _buildMiniNavBtn(Icons.check, RemoteKey.ok, isOk: true),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniNavBtn(IconData icon, RemoteKey key, {bool isOk = false}) {
    return InkWell(
      onTap: () => widget.controller.sendKey(key),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: isOk ? AppColors.onePlusRed.withValues(alpha: 0.8) : Colors.white12,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }
}
