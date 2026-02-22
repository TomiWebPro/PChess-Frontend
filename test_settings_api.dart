import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
// Removed: import 'package:flutter/foundation.dart'; // For debugPrint

// Mock Settings class based on API documentation and ApiService usage
class Settings {
  final int userElo;
  final int maxEvaluationStrength;
  final String pieceSet;
  final String boardTheme;
  final String apiKey;
  final String userLocale;
  final String model;

  Settings({
    required this.userElo,
    required this.maxEvaluationStrength,
    required this.pieceSet,
    required this.boardTheme,
    required this.apiKey,
    required this.userLocale,
    required this.model,
  });

  factory Settings.fromJson(Map<String, dynamic> json) {
    return Settings(
      userElo: json['user_elo'] ?? 0,
      maxEvaluationStrength: json['max_evaluation_strength'] ?? 0,
      pieceSet: json['piece_set'] ?? 'default',
      boardTheme: json['board_theme'] ?? 'blue',
      apiKey: json['API_key'] ?? '',
      userLocale: json['user_locale'] ?? 'en',
      model: json['model'] ?? '',
    );
  }

  @override
  String toString() {
    return '''
Settings(
  userElo: $userElo,
  maxEvaluationStrength: $maxEvaluationStrength,
  pieceSet: '$pieceSet',
  boardTheme: '$boardTheme',
  apiKey: '$apiKey',
  userLocale: '$userLocale',
  model: '$model',
)''';
  }
}

// Mock ApiService to isolate the getSettings call
class MockApiService {
  // Removed: static const String _baseUrl = 'http://localhost:8787';
  // Removed: static const Duration _timeoutDuration = Duration(seconds: 10);

  Future<Settings> getSettings() async {
    // Mocking a successful API response
    final mockJsonResponse = {
      "user_elo": 800,
      "max_evaluation_strength": 15,
      "show_boarder": 1,
      "piece_set": "default",
      "board_theme": "blue",
      "piece_shift_method": "drag",
      "API_key": "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",
      "user_locale": "en",
      "model": "openai/gpt-5-chat"
    };
    
    // Simulate a successful HTTP response
    // http.Response expects a String body
    final mockResponse = http.Response(json.encode(mockJsonResponse), 200);
    
    // The original logic checked statusCode and decoded body.
    // Since we are simulating a successful response, we can directly parse it.
    final Map<String, dynamic> data = json.decode(mockResponse.body);
    return Settings.fromJson(data);
    
    // The original error handling for non-200 status or timeout is not needed here
    // as we are simulating a perfect scenario.
  }
}

Future<void> main() async {
  final mockApiService = MockApiService();
  try {
    print('Attempting to fetch settings...'); // Using print instead of debugPrint
    final settings = await mockApiService.getSettings();
    print('Successfully fetched settings:'); // Using print instead of debugPrint
    print(settings.toString());
  } catch (e) {
    print('Error fetching settings: $e'); // Using print instead of debugPrint
  }
}
