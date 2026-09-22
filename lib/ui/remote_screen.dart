import 'package:flutter/material.dart';
import '../services/remote_controller.dart';
import '../utils/constants.dart';
import 'widgets/top_controls_widget.dart';
import 'widgets/dpad_widget.dart';
import 'widgets/system_buttons_widget.dart';
import 'widgets/volume_rocker_widget.dart';
import 'widgets/app_shortcuts_widget.dart';
import 'widgets/discovery_sheet.dart';

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
}
