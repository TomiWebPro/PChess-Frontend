import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class AiAnalysisWidget extends StatefulWidget {
  final Stream<String> analysisStream;
  final bool isLoading;

  const AiAnalysisWidget({
    super.key,
    required this.analysisStream,
    required this.isLoading,
  });

  @override
  State<AiAnalysisWidget> createState() => _AiAnalysisWidgetState();
}

class _AiAnalysisWidgetState extends State<AiAnalysisWidget> {
  final List<String> _loadingMessages = [
    'Analyzing Chess Principles...',
    'Evaluating Positional Advantages...',
    'Checking for Tactical Oversights...',
    'Calculating Forcing Moves...',
    'Reviewing Opening Theory...',
    'Assessing Endgame Scenarios...',
  ];
  int _currentMessageIndex = 0;
  Timer? _timer;
  String _currentAnalysis = '';
  StreamSubscription? _streamSubscription;

  @override
  void initState() {
    super.initState();
    if (widget.isLoading) {
      _startLoadingAnimation();
    }
    _subscribeToStream();
  }

  @override
  void didUpdateWidget(AiAnalysisWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading && !oldWidget.isLoading) {
      _startLoadingAnimation();
      setState(() {
        _currentAnalysis = '';
      });
    } else if (!widget.isLoading && oldWidget.isLoading) {
      _stopLoadingAnimation();
    }

    if (widget.analysisStream != oldWidget.analysisStream) {
      _streamSubscription?.cancel();
      setState(() {
        _currentAnalysis = '';
      });
      _subscribeToStream();
    }
  }

  void _subscribeToStream() {
    _streamSubscription = widget.analysisStream.listen((chunk) {
      if (mounted) {
        // Stop the loading animation as soon as the first chunk with content arrives.
        if ((_timer?.isActive ?? false) && chunk.isNotEmpty) {
          _stopLoadingAnimation();
        }
        setState(() {
          _currentAnalysis += chunk;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _streamSubscription?.cancel();
    super.dispose();
  }

  void _startLoadingAnimation() {
    _currentMessageIndex = 0;
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        setState(() {
          _currentMessageIndex =
              (_currentMessageIndex + 1) % _loadingMessages.length;
        });
      }
    });
  }

  void _stopLoadingAnimation() {
    _timer?.cancel();
  }

  Widget _buildContent() {
    if (widget.isLoading && _currentAnalysis.isEmpty) {
      return Center(child: Text(_loadingMessages[_currentMessageIndex]));
    } else if (_currentAnalysis.isNotEmpty) {
      return MarkdownBody(data: _currentAnalysis);
    } else {
      return const Center(child: Text('Make a move to get an AI analysis.'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI Analysis',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16.0),
          Expanded(
            child: SingleChildScrollView(
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }
}
