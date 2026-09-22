import 'package:flutter/material.dart';
import '../services/remote_controller.dart';
import '../utils/constants.dart';
import 'widgets/top_controls_widget.dart';
import 'widgets/dpad_widget.dart';
import 'widgets/system_buttons_widget.dart';
import 'widgets/volume_rocker_widget.dart';
import 'widgets/app_shortcuts_widget.dart';
import 'widgets/discovery_sheet.dart';
import 'widgets/macro_recording_banner.dart';
import 'widgets/custom_macros_widget.dart';

class RemoteScreen extends StatefulWidget {
  const RemoteScreen({Key? key}) : super(key: key);

  @override
  State<RemoteScreen> createState() => _RemoteScreenState();
}

class _RemoteScreenState extends State<RemoteScreen> {
  late final RemoteController _controller;
  bool _showLogs = false;

  @override
  void initState() {
    super.initState();
    _controller = RemoteController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openDiscovery() {
    DiscoverySheet.show(context, _controller);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Column(
              children: [
                // Top App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: AppColors.onePlusRed,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Center(
                              child: Text(
                                '1+',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'OnePlus TV Remote',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          // TV Companion Bridge Indicator / Connection Button
                          InkWell(
                            onTap: () => _showCompanionDialog(context),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: _controller.isCompanionConnected
                                    ? const Color(0xFF10281F)
                                    : const Color(0xFF1F1F28),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _controller.isCompanionConnected
                                      ? AppColors.statusConnected
                                      : Colors.white24,
                                  width: 1.2,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.tv,
                                    size: 14,
                                    color: _controller.isCompanionConnected
                                        ? AppColors.statusConnected
                                        : Colors.white54,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _controller.isCompanionConnected
                                        ? 'TV: ${_controller.tvScreenState.displayName}'
                                        : 'TV Bridge',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: _controller.isCompanionConnected
                                          ? AppColors.statusConnected
                                          : Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            icon: Icon(
                              _showLogs ? Icons.terminal : Icons.terminal_outlined,
                              color: _showLogs ? AppColors.onePlusRed : Colors.white54,
                              size: 22,
                            ),
                            tooltip: 'Toggle Protocol Logs',
                            onPressed: () {
                              setState(() {
                                _showLogs = !_showLogs;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Main Remote Shell Container (Scrollable for compact screens)
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 380),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                        decoration: BoxDecoration(
                          color: AppColors.remoteBody,
                          borderRadius: BorderRadius.circular(AppConstants.remoteBorderRadius),
                          border: Border.all(color: AppColors.remoteBevel, width: 2),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black87,
                              blurRadius: 32,
                              spreadRadius: 4,
                              offset: Offset(0, 12),
                            ),
                            BoxShadow(
                              color: Color(0x18FFFFFF),
                              blurRadius: 2,
                              offset: Offset(0, -1),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Macro Recording / Playback Live Banner
                            MacroRecordingBanner(
                              controller: _controller,
                              onSavePressed: () => CustomMacrosWidget.showSaveMacroDialog(context, _controller),
                            ),

                            // Header controls: Power, Status, Mute, Mode
                            TopControlsWidget(
                              controller: _controller,
                              onOpenDiscovery: _openDiscovery,
                            ),
                            const SizedBox(height: 28),

                            // D-pad Navigation Wheel + OK
                            DpadWidget(controller: _controller),
                            const SizedBox(height: 24),

                            // System Controls: Back and Home
                            SystemButtonsWidget(controller: _controller),
                            const SizedBox(height: 22),

                            // Volume Rocker: Vol -, Assistant, Vol +
                            VolumeRockerWidget(controller: _controller),
                            const SizedBox(height: 24),

                            // App Shortcut Pills: Netflix, Menu, Prime, YouTube
                            AppShortcutsWidget(controller: _controller),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Collapsible Live Protocol Log Drawer
                if (_showLogs) _buildLogDrawer(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLogDrawer() {
    return Container(
      height: 150,
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Color(0xFF0A0A0C),
        border: Border(top: BorderSide(color: AppColors.buttonBorder, width: 1.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Live Protocol Logs',
                style: TextStyle(color: AppColors.onePlusRed, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              Text(
                'TLS 1.2 / Protobuf / HID',
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: _controller.recentLogs.length,
              itemBuilder: (context, index) {
                final log = _controller.recentLogs[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    log,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontFamily: 'monospace',
                      fontSize: 11,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showCompanionDialog(BuildContext context) {
    final ipController = TextEditingController(
      text: _controller.companionClient.connectedIp ?? '192.168.1.',
    );

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isConnected = _controller.isCompanionConnected;
            final isConnecting = _controller.companionClient.isConnecting;
            final state = _controller.tvScreenState;

            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E28),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isConnected
                          ? AppColors.statusConnected.withValues(alpha: 0.15)
                          : AppColors.onePlusRed.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.tv,
                      color: isConnected ? AppColors.statusConnected : AppColors.onePlusRed,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'TV Companion Bridge',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isConnected) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10281F),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.statusConnected, width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.check_circle, color: AppColors.statusConnected, size: 16),
                                SizedBox(width: 6),
                                Text(
                                  'Companion Active (Verified Mode)',
                                  style: TextStyle(
                                    color: AppColors.statusConnected,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'TV IP: ${_controller.companionClient.connectedIp}:8765',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Current App: ${state.displayName} (${state.package.isEmpty ? "Launcher" : state.package})',
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            if (state.focused.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Focused: "${state.focused}"',
                                style: const TextStyle(color: Colors.white70, fontSize: 11),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.power_settings_new, size: 16),
                        label: const Text('Disconnect TV Bridge'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white12,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(40),
                        ),
                        onPressed: () async {
                          await _controller.disconnectCompanion();
                          setDialogState(() {});
                        },
                      ),
                    ] else ...[
                      const Text(
                        'Connect directly to the OnePlus TV Companion app installed on your TV for real-time verification and instant 1-click app launching.',
                        style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: ipController,
                        style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
                        decoration: InputDecoration(
                          labelText: 'TV IP Address',
                          labelStyle: const TextStyle(color: Colors.white60),
                          hintText: 'e.g. 192.168.1.15',
                          hintStyle: const TextStyle(color: Colors.white24),
                          filled: true,
                          fillColor: const Color(0xFF14141C),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.white24),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.onePlusRed),
                          ),
                        ),
                        keyboardType: TextInputType.datetime,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Tip: Open the OnePlus TV Companion app on your TV to see the exact IP address.',
                        style: TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.onePlusRed,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(44),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: isConnecting
                            ? null
                            : () async {
                                final ip = ipController.text.trim();
                                if (ip.isEmpty) return;
                                setDialogState(() {});
                                final ok = await _controller.connectCompanion(ip);
                                setDialogState(() {});
                                if (ok && context.mounted) {
                                  Navigator.pop(ctx);
                                }
                              },
                        child: isConnecting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text('Connect to TV Companion', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF14141E),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.download, color: AppColors.statusConnected, size: 16),
                                SizedBox(width: 6),
                                Text(
                                  'Download TV Companion APK',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'GitHub Direct Download Links:',
                              style: TextStyle(color: Colors.white60, fontSize: 11),
                            ),
                            const SizedBox(height: 8),
                            // Link 1: Direct Raw APK
                            InkWell(
                              onTap: () {
                                Clipboard.setData(const ClipboardData(
                                  text: 'https://raw.githubusercontent.com/devanandd7/oneplus-remote/tv_companion/OnePlusTvCompanion.apk',
                                ));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Direct Raw APK link copied!')),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.black45,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.white10),
                                ),
                                child: const Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '1. Direct Raw APK (1-Click)',
                                        style: TextStyle(color: AppColors.statusConnected, fontSize: 11, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    Icon(Icons.copy, color: Colors.white60, size: 14),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Link 2: GitHub File Page
                            InkWell(
                              onTap: () {
                                Clipboard.setData(const ClipboardData(
                                  text: 'https://github.com/devanandd7/oneplus-remote/blob/tv_companion/OnePlusTvCompanion.apk',
                                ));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('GitHub File Page link copied!')),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.black45,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.white10),
                                ),
                                child: const Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '2. GitHub File Page',
                                        style: TextStyle(color: Colors.white70, fontSize: 11),
                                      ),
                                    ),
                                    Icon(Icons.copy, color: Colors.white60, size: 14),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close', style: TextStyle(color: Colors.white60)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
