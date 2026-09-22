import 'package:flutter/material.dart';
import '../../models/tv_device.dart';
import '../../models/connection_mode.dart';
import '../../services/remote_controller.dart';
import '../../utils/constants.dart';
import 'pairing_dialog.dart';

class DiscoverySheet extends StatefulWidget {
  final RemoteController controller;

  const DiscoverySheet({Key? key, required this.controller}) : super(key: key);

  static void show(BuildContext context, RemoteController controller) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => DiscoverySheet(controller: controller),
    );
  }

  @override
  State<DiscoverySheet> createState() => _DiscoverySheetState();
}

class _DiscoverySheetState extends State<DiscoverySheet> {
  final TextEditingController _ipController = TextEditingController();
  List<Map<String, String>> _bondedBtDevices = [];
  bool _isLoadingBt = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.controller.currentMode == RemoteEngineMode.wifi) {
        widget.controller.scanForWifiTvs();
      } else {
        _loadBondedBtDevices();
      }
    });
  }

  Future<void> _loadBondedBtDevices() async {
    setState(() {
      _isLoadingBt = true;
    });
    final devices = await widget.controller.getBondedBtDevices();
    if (mounted) {
      setState(() {
        _bondedBtDevices = devices;
        _isLoadingBt = false;
      });
    }
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        return Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          decoration: const BoxDecoration(
            color: AppColors.remoteBody,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            border: Border(top: BorderSide(color: AppColors.buttonBorder, width: 1.5)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Grab handle
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
                const SizedBox(height: 16),

                // Title row with Expanded to prevent overflow
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.controller.currentMode == RemoteEngineMode.wifi
                            ? 'OnePlus TV (Wi-Fi)'
                            : 'Bluetooth Remote Devices',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.controller.currentMode == RemoteEngineMode.wifi)
                      IconButton(
                        icon: const Icon(Icons.refresh, color: AppColors.onePlusRed),
                        tooltip: 'Scan Network',
                        onPressed: () => widget.controller.scanForWifiTvs(),
                      )
                    else
                      IconButton(
                        icon: const Icon(Icons.refresh, color: AppColors.assistantBlue),
                        tooltip: 'Refresh Paired Devices',
                        onPressed: _loadBondedBtDevices,
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                if (widget.controller.currentMode == RemoteEngineMode.bluetooth) ...[
                  if (_isLoadingBt)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(color: AppColors.assistantBlue),
                      ),
                    )
                  else if (_bondedBtDevices.isNotEmpty) ...[
                    const Text(
                      'Paired Bluetooth Devices:',
                      style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _bondedBtDevices.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (ctx, idx) {
                        final d = _bondedBtDevices[idx];
                        final name = d['name'] ?? 'Device';
                        final addr = d['address'] ?? '';
                        final isConnected = widget.controller.status == ConnectionStatus.connected &&
                            widget.controller.connectedDeviceAddress == addr;
                        return Container(
                          decoration: BoxDecoration(
                            color: AppColors.buttonDark,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isConnected ? AppColors.statusConnected : AppColors.buttonBorder,
                            ),
                          ),
                          child: ListTile(
                            leading: Icon(
                              name.toLowerCase().contains('tv') ? Icons.tv : Icons.bluetooth,
                              color: isConnected ? AppColors.statusConnected : AppColors.assistantBlue,
                            ),
                            title: Text(
                              name,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              addr,
                              style: const TextStyle(color: Colors.white54, fontSize: 11),
                            ),
                            trailing: SizedBox(
                              height: 36,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isConnected ? AppColors.statusConnected : AppColors.assistantBlue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () async {
                                  await widget.controller.connectBtDevice(addr, name);
                                  if (context.mounted) {
                                    Navigator.of(context).pop();
                                  }
                                },
                                child: Text(
                                  isConnected ? 'Connected' : 'Connect',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Bluetooth pairing instructions card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.buttonDark,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.buttonBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'How to Pair with OnePlus TV:',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        SizedBox(height: 6),
                        Text(
                          '1. On your OnePlus TV, open Settings → Remotes & Accessories → Add Accessory.\n'
                          '2. Select "OnePlus TV Remote" when it appears.\n'
                          '3. Once paired, tap "Connect" above to start controlling!',
                          style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Wi-Fi discovered list
                  if (widget.controller.status == ConnectionStatus.scanning) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(color: AppColors.onePlusRed),
                            SizedBox(height: 12),
                            Text(
                              'Scanning network for OnePlus TVs...',
                              style: TextStyle(color: Colors.white54, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else if (widget.controller.discoveredDevices.isEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          'No TVs detected automatically.\nEnter TV IP address below.',
                          style: TextStyle(color: Colors.white54, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ] else ...[
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: widget.controller.discoveredDevices.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (ctx, index) {
                        final device = widget.controller.discoveredDevices[index];
                        final isSelected = widget.controller.selectedTv?.ipAddress == device.ipAddress &&
                            widget.controller.status == ConnectionStatus.connected;
                        return Container(
                          decoration: BoxDecoration(
                            color: AppColors.buttonDark,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? AppColors.statusConnected : AppColors.buttonBorder,
                            ),
                          ),
                          child: ListTile(
                            leading: Icon(
                              Icons.tv,
                              color: isSelected ? AppColors.statusConnected : AppColors.onePlusRed,
                            ),
                            title: Text(
                              device.name,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              device.ipAddress,
                              style: const TextStyle(color: Colors.white54, fontSize: 11),
                            ),
                            trailing: SizedBox(
                              height: 36,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isSelected ? AppColors.statusConnected : AppColors.onePlusRed,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () async {
                                  Navigator.of(context).pop();
                                  await widget.controller.startWifiPairing(device);
                                  if (context.mounted) {
                                    PairingDialog.show(context, widget.controller);
                                  }
                                },
                                child: Text(
                                  isSelected ? 'Connected' : 'Pair',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],

                  const SizedBox(height: 16),
                  const Divider(color: AppColors.buttonBorder),
                  const SizedBox(height: 8),

                  // Manual IP input
                  const Text(
                    'Or Connect via IP:',
                    style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _ipController,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'e.g. 192.168.1.8',
                            hintStyle: const TextStyle(color: Colors.white30),
                            fillColor: AppColors.buttonDark,
                            filled: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: AppColors.buttonBorder),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 44,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.onePlusRed,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          onPressed: () async {
                            final ip = _ipController.text.trim();
                            if (ip.isNotEmpty) {
                              Navigator.of(context).pop();
                              final customDevice = TvDevice(
                                id: ip,
                                name: 'OnePlus TV ($ip)',
                                ipAddress: ip,
                              );
                              await widget.controller.startWifiPairing(customDevice);
                              if (context.mounted) {
                                PairingDialog.show(context, widget.controller);
                              }
                            }
                          },
                          child: const Text('Connect', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}
