import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/remote_key.dart';

class GeminiVisionAnalysis {
  final String currentScreen;
  final String currentFocus;
  final String activeTab;
  final String target;
  final List<RemoteKey> steps;
  final List<String> rawStepNames;
  final String explanation;
  final bool success;
  final String? errorMessage;

  const GeminiVisionAnalysis({
    required this.currentScreen,
    required this.currentFocus,
    required this.activeTab,
    required this.target,
    required this.steps,
    required this.rawStepNames,
    required this.explanation,
    required this.success,
    this.errorMessage,
  });

  factory GeminiVisionAnalysis.error(String message) {
    return GeminiVisionAnalysis(
      currentScreen: 'Unknown',
      currentFocus: 'Unknown',
      activeTab: '',
      target: '',
      steps: [],
      rawStepNames: [],
      explanation: message,
      success: false,
      errorMessage: message,
    );
  }
}

class GeminiVisionService {
  static const String _prefApiKey = 'gemini_api_key';
  static const String _prefModel = 'gemini_model_name';

  static const String defaultModel = 'gemini-2.0-flash';

  Future<String?> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefApiKey);
  }

  Future<void> saveApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefApiKey, apiKey.trim());
  }

  Future<String> getSelectedModel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefModel) ?? defaultModel;
  }

  Future<void> saveSelectedModel(String model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefModel, model);
  }

  /// Analyzes a photo of the TV screen and determines the exact navigation keys
  Future<GeminiVisionAnalysis> analyzeTvScreen({
    required Uint8List imageBytes,
    required String targetGoal,
  }) async {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.trim().isEmpty) {
      return GeminiVisionAnalysis.error(
        'Gemini API Key missing! Tap the ⚙️ icon to set your API Key.',
      );
    }

    final model = await getSelectedModel();
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
    );

    final base64Image = base64Encode(imageBytes);

    final prompt = '''
You are an expert OnePlus Android TV navigation AI assistant.
Analyze this photo of the TV screen and navigate to the target: "$targetGoal".

Inspect the TV screen carefully:
1. Current screen: (e.g. Android TV Home, Inputs sidebar, Settings overlay, YouTube, etc.)
2. Active navbar tab if visible (look for underline or highlighted tab, e.g. "Home", "Discover", "Apps").
3. Current focused / highlighted element: (look for glowing white borders, enlarged cards, or highlighted text, e.g. "Netflix", "HDMI 2", "Network & Internet").
4. Calculate the exact sequence of remote control D-Pad keys needed to reach the target from the current focus.

Available remote keys you can output:
["UP", "DOWN", "LEFT", "RIGHT", "OK", "BACK", "HOME", "MENU", "SETTINGS", "INPUT"]

Respond strictly in valid JSON format only (no markdown code blocks, no backticks):
{
  "currentScreen": "detected screen name",
  "activeTab": "active navbar tab or empty",
  "currentFocus": "currently focused element",
  "target": "$targetGoal",
  "steps": ["UP", "RIGHT", "OK"],
  "explanation": "Short 1-sentence explanation of why these steps reach the target."
}
''';

    final requestBody = {
      'contents': [
        {
          'parts': [
            {'text': prompt},
            {
              'inline_data': {
                'mime_type': 'image/jpeg',
                'data': base64Image,
              }
            }
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.1,
        'maxOutputTokens': 800,
      }
    };

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        final errJson = jsonDecode(response.body);
        final errMsg = errJson['error']?['message'] ?? 'Status ${response.statusCode}';
        return GeminiVisionAnalysis.error('Gemini API Error: $errMsg');
      }

      final resData = jsonDecode(response.body);
      final candidate = resData['candidates']?[0];
      final textContent = candidate?['content']?['parts']?[0]?['text'] as String?;

      if (textContent == null || textContent.trim().isEmpty) {
        return GeminiVisionAnalysis.error('Empty response received from Gemini.');
      }

      // Clean JSON if model returned markdown backticks
      String cleanedJson = textContent.trim();
      if (cleanedJson.startsWith('```json')) {
        cleanedJson = cleanedJson.substring(7);
      } else if (cleanedJson.startsWith('```')) {
        cleanedJson = cleanedJson.substring(3);
      }
      if (cleanedJson.endsWith('```')) {
        cleanedJson = cleanedJson.substring(0, cleanedJson.length - 3);
      }
      cleanedJson = cleanedJson.trim();

      final parsed = jsonDecode(cleanedJson) as Map<String, dynamic>;

      final rawSteps = (parsed['steps'] as List<dynamic>?)
              ?.map((e) => e.toString().toUpperCase())
              .toList() ??
          [];

      final List<RemoteKey> mappedKeys = [];
      for (final step in rawSteps) {
        final key = _mapStringToRemoteKey(step);
        if (key != null) {
          mappedKeys.add(key);
        }
      }

      return GeminiVisionAnalysis(
        currentScreen: parsed['currentScreen'] ?? 'Android TV Screen',
        currentFocus: parsed['currentFocus'] ?? 'Unknown Focus',
        activeTab: parsed['activeTab'] ?? '',
        target: parsed['target'] ?? targetGoal,
        steps: mappedKeys,
        rawStepNames: rawSteps,
        explanation: parsed['explanation'] ?? 'Navigation path calculated by Gemini.',
        success: true,
      );
    } catch (e) {
      debugPrint('[GeminiVision] Error: $e');
      return GeminiVisionAnalysis.error('Vision Analysis Failed: $e');
    }
  }

  RemoteKey? _mapStringToRemoteKey(String keyName) {
    switch (keyName.toUpperCase().trim()) {
      case 'UP':
      case 'DPAD_UP':
        return RemoteKey.dpadUp;
      case 'DOWN':
      case 'DPAD_DOWN':
        return RemoteKey.dpadDown;
      case 'LEFT':
      case 'DPAD_LEFT':
        return RemoteKey.dpadLeft;
      case 'RIGHT':
      case 'DPAD_RIGHT':
        return RemoteKey.dpadRight;
      case 'OK':
      case 'ENTER':
      case 'DPAD_CENTER':
        return RemoteKey.ok;
      case 'BACK':
        return RemoteKey.back;
      case 'HOME':
        return RemoteKey.home;
      case 'MENU':
        return RemoteKey.menu;
      case 'SETTINGS':
        return RemoteKey.settings;
      case 'INPUT':
      case 'INPUTS':
        return RemoteKey.input;
      default:
        return null;
    }
  }
}
