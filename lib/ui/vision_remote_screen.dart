import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/remote_controller.dart';
import '../services/gemini_vision_service.dart';
import '../services/haptic_service.dart';
import '../models/remote_key.dart';
import '../utils/constants.dart';

class VisionRemoteScreen extends StatefulWidget {
  final RemoteController controller;

  const VisionRemoteScreen({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  State<VisionRemoteScreen> createState() => _VisionRemoteScreenState();
}

class _VisionRemoteScreenState extends State<VisionRemoteScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isAnalyzing = false;
  bool _isExecutingSteps = false;

  final GeminiVisionService _visionService = GeminiVisionService();
  GeminiVisionAnalysis? _lastAnalysis;
  final TextEditingController _targetController = TextEditingController();

  String _statusMessage = 'Point camera at TV & select a target';
  int _executingStepIndex = -1;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        // Use back camera
        final backCam = _cameras!.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
          orElse: () => _cameras!.first,
        );

        _cameraController = CameraController(
          backCam,
          ResolutionPreset.medium,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.jpeg,
        );

        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Camera init error: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _analyzeAndNavigate(String target) async {
    if (_isAnalyzing || _isExecutingSteps) return;
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      _showToast('Camera not ready');
      return;
    }

    final apiKey = await _visionService.getApiKey();
    if (apiKey == null || apiKey.trim().isEmpty) {
      _showApiKeyDialog();
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _statusMessage = 'Capturing TV Screen & Asking Gemini...';
      _executingStepIndex = -1;
    });

    try {
      HapticService.buttonClick();
      final XFile photo = await _cameraController!.takePicture();
      final Uint8List bytes = await photo.readAsBytes();

      final analysis = await _visionService.analyzeTvScreen(
        imageBytes: bytes,
        targetGoal: target,
      );

      if (!mounted) return;

      setState(() {
        _lastAnalysis = analysis;
        _isAnalyzing = false;
      });

      if (!analysis.success) {
        setState(() {
          _statusMessage = analysis.errorMessage ?? 'Analysis failed';
        });
        _showToast(analysis.errorMessage ?? 'Error analyzing screen');
        return;
      }

      // Execute steps sequentially
      await _executeCalculatedSteps(analysis);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _statusMessage = 'Error: $e';
        });
      }
    }
  }

  Future<void> _executeCalculatedSteps(GeminiVisionAnalysis analysis) async {
    if (analysis.steps.isEmpty) {
      setState(() {
        _statusMessage = 'Target "${analysis.target}" already reached or no steps needed!';
      });
      return;
    }

    setState(() {
      _isExecutingSteps = true;
      _statusMessage = 'AI Executing ${analysis.steps.length} steps...';
    });

    for (int i = 0; i < analysis.steps.length; i++) {
      if (!mounted) break;
      setState(() {
        _executingStepIndex = i;
        _statusMessage = 'Step ${i + 1}/${analysis.steps.length}: Sending ${analysis.rawStepNames[i]}...';
      });

      final key = analysis.steps[i];
      await widget.controller.sendKey(key);
      HapticService.navigationClick();

      // Give TV 400ms to update focus visually
      await Future.delayed(const Duration(milliseconds: 400));
    }

    if (mounted) {
      setState(() {
        _isExecutingSteps = false;
        _executingStepIndex = -1;
        _statusMessage = '✅ Successfully navigated to "${analysis.target}"!';
      });
    }
  }

  void _showToast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF222234),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showApiKeyDialog() async {
    final currentKey = await _visionService.getApiKey() ?? '';
    final textController = TextEditingController(text: currentKey);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.auto_awesome, color: Colors.amber, size: 22),
            SizedBox(width: 8),
            Text(
              'Gemini AI Settings',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your Google Gemini API Key. Get one for free from Google AI Studio (aistudio.google.com):',
              style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: textController,
              obscureText: true,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'AIzaSy...',
                hintStyle: const TextStyle(color: Colors.white30),
                filled: true,
                fillColor: const Color(0xFF12121A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.onePlusRed),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.onePlusRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await _visionService.saveApiKey(textController.text.trim());
              Navigator.pop(ctx);
              _showToast('Gemini API Key saved!');
            },
            child: const Text('Save Key'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12121A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161624),
        elevation: 0,
        title: Row(
          children: const [
            Icon(Icons.camera_alt_outlined, color: AppColors.onePlusRed, size: 20),
            SizedBox(width: 8),
            Text(
              'AI Vision Remote',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white70),
            tooltip: 'Gemini API Key Setup',
            onPressed: _showApiKeyDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // TOP 50%: Live Camera Preview
          Expanded(
            flex: 5,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_isCameraInitialized && _cameraController != null)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                    child: CameraPreview(_cameraController!),
                  )
                else
                  Container(
                    color: Colors.black87,
                    child: const Center(
                      child: CircularProgressIndicator(color: AppColors.onePlusRed),
                    ),
                  ),

                // TV Alignment Frame & Crosshairs
                Center(
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.85,
                    height: (MediaQuery.of(context).size.width * 0.85) * (9 / 16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _isAnalyzing
                            ? Colors.amber
                            : (_isExecutingSteps ? AppColors.statusConnected : Colors.white60),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 8,
                          left: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _isAnalyzing ? Colors.amber : Colors.greenAccent,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _isAnalyzing
                                      ? 'Analyzing Frame...'
                                      : (_isExecutingSteps ? 'Executing Nav...' : 'Align TV Screen Here'),
                                  style: const TextStyle(color: Colors.white, fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // BOTTOM 50%: Gemini Detection & Smart Action Dashboard
          Expanded(
            flex: 5,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFF12121A),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Status & AI Analysis Box
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B1B28),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _isExecutingSteps
                              ? AppColors.statusConnected
                              : (_isAnalyzing ? Colors.amber : Colors.white12),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                size: 16,
                                color: _isAnalyzing ? Colors.amber : Colors.cyanAccent,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _statusMessage,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          if (_lastAnalysis != null && _lastAnalysis!.success) ...[
                            const SizedBox(height: 8),
                            const Divider(color: Colors.white10, height: 1),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Screen:',
                                        style: TextStyle(color: Colors.white38, fontSize: 10),
                                      ),
                                      Text(
                                        _lastAnalysis!.currentScreen,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Focus:',
                                        style: TextStyle(color: Colors.white38, fontSize: 10),
                                      ),
                                      Text(
                                        _lastAnalysis!.currentFocus,
                                        style: const TextStyle(
                                          color: AppColors.statusConnected,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (_lastAnalysis!.rawStepNames.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: List.generate(
                                  _lastAnalysis!.rawStepNames.length,
                                  (idx) {
                                    final step = _lastAnalysis!.rawStepNames[idx];
                                    final isCurrent = _executingStepIndex == idx;
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isCurrent
                                            ? AppColors.onePlusRed
                                            : const Color(0xFF2B2B3E),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        step,
                                        style: TextStyle(
                                          color: isCurrent ? Colors.white : Colors.white70,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Quick AI Targets Header
                    const Text(
                      'Tap Target to Auto-Navigate:',
                      style: TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),

                    // Quick Targets Grid
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildTargetChip('HDMI 1', Icons.settings_input_hdmi, Colors.blueAccent),
                        _buildTargetChip('HDMI 2', Icons.settings_input_hdmi, Colors.purpleAccent),
                        _buildTargetChip('YouTube', Icons.play_arrow, AppColors.onePlusRed),
                        _buildTargetChip('Settings', Icons.settings, Colors.orangeAccent),
                        _buildTargetChip('Inputs', Icons.input_rounded, Colors.tealAccent),
                        _buildTargetChip('Netflix', Icons.movie_outlined, Colors.redAccent),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Custom Command / Search Input
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _targetController,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Custom goal: e.g. "Discover tab"...',
                              hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
                              filled: true,
                              fillColor: const Color(0xFF1B1B28),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.white12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.onePlusRed,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _isAnalyzing || _isExecutingSteps
                              ? null
                              : () {
                                  final goal = _targetController.text.trim();
                                  if (goal.isNotEmpty) {
                                    _analyzeAndNavigate(goal);
                                  }
                                },
                          child: const Icon(Icons.arrow_forward, size: 18),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetChip(String title, IconData icon, Color color) {
    final isBusy = _isAnalyzing || _isExecutingSteps;
    return InkWell(
      onTap: isBusy ? null : () => _analyzeAndNavigate(title),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A28),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 15),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
