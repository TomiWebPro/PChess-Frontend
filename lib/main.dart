import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dartchess/dartchess.dart';
import 'chess_board_widget.dart';
import 'models/settings.dart' as app_settings;
import 'pages/settings_page.dart';
import 'services/api_service.dart';
import 'widgets/ai_analysis_widget.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const ChessDemo(),
    );
  }
}

class ChessDemo extends StatefulWidget {
  const ChessDemo({super.key});

  @override
  State<ChessDemo> createState() => _ChessDemoState();
}

class _ChessDemoState extends State<ChessDemo> {
  Chess _position = Chess.initial;
  NormalMove? _lastMove;
  final ApiService _apiService = ApiService();
  int _userColor = 0; // 0 for white, 1 for black
  int? _currentPuzzleId;
  bool _isLoading = false;
  String _errorMessage = '';
  StreamController<String> _aiAnalysisController = StreamController<String>.broadcast();
  bool _isAiLoading = false;
  app_settings.Settings? _settings;
  StreamSubscription? _aiAnalysisSubscription;

  // Expose the stream for the AiAnalysisWidget
  Stream<String> get _aiAnalysisStream => _aiAnalysisController.stream;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _aiAnalysisController.close();
    _aiAnalysisSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await _loadSettings();
    await _loadRandomPuzzle();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await _apiService.getSettings();
      if(mounted) {
        setState(() {
          _settings = settings;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadRandomPuzzle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final puzzle = await _apiService.getRandomPuzzle();
      final setup = Setup.parseFen(puzzle.fen);
      final newPos = Chess.fromSetup(setup);

      setState(() {
        _position = newPos;
        _lastMove = NormalMove.fromUci(puzzle.lastMove);
        _currentPuzzleId = puzzle.id;
        _userColor = puzzle.userColor;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load puzzle: $e';
        _isLoading = false; // Ensure loading is set to false even on error
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading puzzle: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _nextPuzzle() {
    if (_isLoading) return;

    setState(() {
      _lastMove = null;
    });

    // Add a small delay for a smoother UI transition
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _loadRandomPuzzle();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("PChess"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              final newSettings = await Navigator.push<app_settings.Settings>(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsPage(initialSettings: _settings),
                ),
              );
              if (newSettings != null) {
                setState(() {
                  _settings = newSettings;
                });
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Left side: Chessboard and controls
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  if (_errorMessage.isNotEmpty)
                    Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red),
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _nextPuzzle,
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text("Next Puzzle"),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _settings == null 
                          ? const Center(child: CircularProgressIndicator())
                          : ChessBoardWidget(
                              key: ValueKey(_currentPuzzleId),
                              fen: _position.fen,
                              lastMove: _lastMove,
                              userColor: _userColor,
                              onUserMove: _onUserMove,
                              settings: _settings!,
                            ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Right side: AI Analysis
            Expanded(
              flex: 2,
              child: AiAnalysisWidget(
                analysisStream: _aiAnalysisStream,
                isLoading: _isAiLoading,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onUserMove(NormalMove move, String fen) async {
    debugPrint("User move: ${move.uci}, New FEN: $fen");
    if (_currentPuzzleId == null) return;

    // Cancel any existing analysis stream
    await _aiAnalysisSubscription?.cancel();

    setState(() {
      _position = Chess.fromSetup(Setup.parseFen(fen));
      _lastMove = move;
      _isAiLoading = true;
    });

    try {
      // Ensure settings are loaded and API_key is available
      if (_settings == null || _settings!.apiKey.isEmpty) {
        throw Exception('API key not available. Please set it in settings.');
      }

      // Get the OpenRouter payload from the backend
      final openRouterPayload =
          await _apiService.getOpenRouterPayload(_currentPuzzleId!, move.uci);

      // Stream the response directly from OpenRouter
      debugPrint('Creating OpenRouter stream...');
      final openRouterStream = _apiService.streamOpenRouterResponse(
          openRouterPayload, _settings!.apiKey);
      debugPrint('OpenRouter stream created.');

      // Pipe the OpenRouter stream into our StreamController
      _aiAnalysisSubscription = openRouterStream.listen(
        (data) {
          _aiAnalysisController.add(data);
        },
        onError: (error) {
          if (mounted) {
            setState(() => _isAiLoading = false);
            _aiAnalysisController.addError(error); // Add error to controller
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error getting AI analysis: $error'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        onDone: () {
          if (mounted) {
            setState(() => _isAiLoading = false);
            // No need to close controller here, it's managed by dispose
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isAiLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting AI analysis: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
