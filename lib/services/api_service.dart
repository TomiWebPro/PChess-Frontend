import 'dart:convert';
import 'dart:math';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/settings.dart';
import '../models/puzzle.dart';

class ApiService {
  static const String _baseUrl = 'http://localhost:8787';
  static const Duration _timeoutDuration = Duration(seconds: 10);
  static const String _openRouterBaseUrl = 'https://openrouter.ai/api/v1';
  
  // Settings endpoints
  Future<Settings> getSettings() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/settings'),
      ).timeout(_timeoutDuration);
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return Settings.fromJson(data);
      } else {
        throw Exception('Failed to load settings: ${response.statusCode}');
      }
    } on TimeoutException {
      throw Exception('Request timeout while loading settings');
    }
  }
  
  Future<void> updateSettings(Settings settings) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/settings'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(settings.toJson()),
      ).timeout(_timeoutDuration);
      
      if (response.statusCode != 200) {
        throw Exception('Failed to update settings: ${response.statusCode}');
      }
    } on TimeoutException {
      throw Exception('Request timeout while updating settings');
    }
  }

  // OpenRouter models endpoint
  Future<List<String>> getOpenRouterModels() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/openrouter/models'),
      ).timeout(_timeoutDuration);
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return List<String>.from(data['model_ids']);
      } else {
        throw Exception('Failed to load models: ${response.statusCode}');
      }
    } on TimeoutException {
      throw Exception('Request timeout while loading models');
      }
  }

  Future<List<String>> getPieceSets() async {
    // In a real app, this would fetch from an API endpoint.
    // For this example, we return a static list.
    await Future.delayed(const Duration(milliseconds: 100));
    return ['maestro', 'cardinal', 'merida'];
  }
  
  // Puzzle endpoints
  Future<PuzzleList> getAvailablePuzzleIds() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/available/ids'),
      ).timeout(_timeoutDuration);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return PuzzleList.fromJson(data);
      } else {
        throw Exception('Failed to load puzzle IDs: ${response.statusCode}');
      }
    } on TimeoutException {
      throw Exception('Request timeout while loading puzzle IDs');
    }
  }
  
  Future<Puzzle> getPuzzleById(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/fen/$id'),
      ).timeout(_timeoutDuration);
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return Puzzle.fromJson(data, id);
      } else {
        throw Exception('Failed to load puzzle: ${response.statusCode}');
      }
    } on TimeoutException {
      throw Exception('Request timeout while loading puzzle');
    }
  }
  
  Future<Map<String, dynamic>> getOpenRouterPayload(
      int puzzleId, String userMove) async {
    final request = http.Request(
      'POST',
      Uri.parse('$_baseUrl/ai-response'),
    )
      ..headers['Content-Type'] = 'application/json'
      ..body = json.encode({
        'puzzle_id': puzzleId,
        'user_move': userMove,
      });

    try {
      final response = await request.send().then(http.Response.fromStream);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
            'Failed to get OpenRouter payload: ${response.statusCode}, Body: ${response.body}');
      }
    } on TimeoutException {
      throw Exception('Request timeout while getting OpenRouter payload');
    } catch (e) {
      throw Exception('Failed to get OpenRouter payload: $e');
    }
  }

  Stream<String> streamOpenRouterResponse(
      Map<String, dynamic> openRouterPayload, String apiKey) {
    final controller = StreamController<String>();

    final request = http.Request(
      'POST',
      Uri.parse('$_openRouterBaseUrl/chat/completions'),
    )
      ..headers['Content-Type'] = 'application/json'
      ..headers['Authorization'] = 'Bearer $apiKey'
      ..body = json.encode(openRouterPayload);

    Future<void> process() async {
      try {
        final streamedResponse = await request.send().timeout(_timeoutDuration);

        if (streamedResponse.statusCode == 200) {
          String buffer = '';
          await for (final byteChunk in streamedResponse.stream) {
            final chunkString = utf8.decode(byteChunk, allowMalformed: true);
            buffer += chunkString;

            List<String> lines = buffer.split('\n');
            buffer = lines.removeLast();

            for (String line in lines) {
              if (line.startsWith('data:')) {
                final data = line.substring(5).trim();
                if (data == '[DONE]') {
                  return; // End of stream
                }
                try {
                  final Map<String, dynamic> jsonResponse = json.decode(data);
                  final List<dynamic> choices = jsonResponse['choices'];
                  if (choices.isNotEmpty) {
                    final Map<String, dynamic> delta = choices[0]['delta'];
                    if (delta['content'] != null) {
                      controller.add(delta['content']);
                    }
                  }
                } catch (e) {
                  // Ignore parsing errors for now
                }
              }
            }
          }
        } else {
          final errorBody = await streamedResponse.stream.bytesToString();
          controller.addError(Exception(
              'Failed to stream OpenRouter response: ${streamedResponse.statusCode}, Body: $errorBody'));
        }
      } on TimeoutException {
        controller.addError(
            Exception('Request timeout while streaming OpenRouter response'));
      } catch (e) {
        controller.addError(
            Exception('Failed to stream OpenRouter response: $e'));
      } finally {
        if (!controller.isClosed) {
          controller.close();
        }
      }
    }

    process();
    return controller.stream;
  }

  Future<Puzzle> getRandomPuzzle() async {
    try {
      final puzzleList = await getAvailablePuzzleIds();
      if (puzzleList.ids.isEmpty) {
        throw Exception('No puzzles available');
      }
      final random = Random();
      final randomIndex = random.nextInt(puzzleList.ids.length);
      final randomPuzzleId = puzzleList.ids[randomIndex];
      return await getPuzzleById(randomPuzzleId);
    } catch (e) {
      throw Exception('Failed to load random puzzle: $e');
    }
  }
}
