// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:chessground/chessground.dart' hide PieceSet;
import 'package:dartchess/dartchess.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:pchess_frontend/board_theme.dart';
import 'package:pchess_frontend/models/settings.dart';
import 'package:pchess_frontend/piece_set.dart';

class ChessBoardWidget extends StatefulWidget {
  final String fen;
  final NormalMove? lastMove;
  final int userColor; // 0 for white, 1 for black
  final Function(NormalMove move, String fen) onUserMove;
  final Settings settings;

  const ChessBoardWidget({
    super.key,
    required this.fen,
    required this.lastMove,
    required this.userColor,
    required this.onUserMove,
    required this.settings,
  });

  @override
  State<ChessBoardWidget> createState() => _ChessBoardWidgetState();
}

class _ChessBoardWidgetState extends State<ChessBoardWidget> {
  late Chess _initialPosition;
  late Chess _position;
  NormalMove? _promotionPending;
  bool _isBoardLocked = false;
  bool _isBoardReadyForUserMove = false;

  @override
  void initState() {
    super.initState();
    _loadNewPuzzle();
  }

  void _loadNewPuzzle() {
    _initialPosition = Chess.fromSetup(Setup.parseFen(widget.fen));
    _position = _initialPosition;
    _isBoardLocked = false;
    _isBoardReadyForUserMove = false;
    _promotionPending = null;
    
    // Apply the last move after a delay for animation
    if (widget.lastMove != null && _initialPosition.isLegal(widget.lastMove!)) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _position = _position.play(widget.lastMove!) as Chess;
            _isBoardReadyForUserMove = true;
          });
        }
      });
    } else {
      _isBoardReadyForUserMove = true;
    }
  }

  @override
  void didUpdateWidget(covariant ChessBoardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fen != widget.fen || oldWidget.userColor != widget.userColor) {
      _loadNewPuzzle();
    }
  }

  // Method to reset the user move flag (for external use)
  void resetUserMove() {
    setState(() {
      _isBoardLocked = false;
    });
  }
  
  // Method to reset the animation (for external use)
  void resetAnimation() {
    setState(() {
      _loadNewPuzzle();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Use LayoutBuilder to get the available space for the chess board
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate the maximum size for the chess board
        // We'll use the smaller of width/height, but leave some margin
        final maxWidth = constraints.maxWidth;
        final maxHeight = constraints.maxHeight;
        final size = maxWidth > maxHeight ? maxHeight : maxWidth;
        
        // Ensure we don't exceed the available space
        final boardSize = size > 0 ? size : 300.0;

        final boardTheme = BoardTheme.values.firstWhere(
          (e) => e.name == widget.settings.boardTheme,
          orElse: () => BoardTheme.blue,
        );

        final pieceSet = PieceSet.values.firstWhere(
          (e) => e.name == widget.settings.pieceSet,
          orElse: () => PieceSet.maestro,
        );

        final userSide = widget.userColor == 0 ? Side.white : Side.black;

        return Chessboard(
          size: boardSize,
          orientation: userSide,
          fen: _position.fen,
          lastMove: _isBoardReadyForUserMove ? widget.lastMove : null,
          game: _buildGame(),
          settings: ChessboardSettings(
            animationDuration: const Duration(milliseconds: 300),
            colorScheme: boardTheme.colors,
            enableCoordinates: true,
            pieceAssets: pieceSet.assets,
          ),
        );
      },
    );
  }

  /// Convert dartchess legalMoves -> chessground ValidMoves
  ValidMoves _makeLegalMoves(Chess pos) {
    final map = <Square, ISet<Square>>{};
    for (final entry in pos.legalMoves.entries) {
      map[entry.key] = ISet(entry.value.squares);
    }
    return IMap(map);
  }

  /// Check if a move requires promotion
  bool _needsPromotion(Chess pos, NormalMove mv) {
    final piece = pos.board.pieceAt(mv.from);
    if (piece == null || piece.role != Role.pawn) return false;

    final destRank = mv.to.rank;
    if (piece.color == Side.white && destRank == Rank.eighth) return true;
    if (piece.color == Side.black && destRank == Rank.first) return true;
    return false;
  }

  GameData _buildGame() {
    final userSide = widget.userColor == 0 ? Side.white : Side.black;
    final isUserTurn = _position.turn == userSide;
    final allowUserMove = _isBoardReadyForUserMove && !_isBoardLocked && isUserTurn;

    return GameData(
      sideToMove: _position.turn,
      promotionMove: _promotionPending,
      onPromotionSelection: (Role? role) {
        if (_promotionPending == null || role == null) {
          setState(() => _promotionPending = null);
          return;
        }

        final promoted = _promotionPending!.withPromotion(role);
        final normalized = _position.normalizeMove(promoted);

        if (_position.isLegal(normalized)) {
          final newPos = _position.play(normalized) as Chess;
          setState(() {
            _position = newPos;
            _isBoardLocked = true;
            _promotionPending = null;
          });
          widget.onUserMove(promoted, newPos.fen);
        } else {
          setState(() => _promotionPending = null);
        }
      },

      playerSide: allowUserMove ? PlayerSide.both : PlayerSide.none,

      validMoves: allowUserMove ? _makeLegalMoves(_position) : IMap(const {}),

      onMove: (NormalMove mv, {bool? isDrop}) {
        if (_isBoardLocked) return;

        // If move requires promotion, set pending and wait for selection
        if (_needsPromotion(_position, mv) && mv.promotion == null) {
          setState(() => _promotionPending = mv);
          return;
        }

        final normalized = _position.normalizeMove(mv);
        if (_position.isLegal(normalized)) {
          final newPos = _position.play(normalized) as Chess;
          setState(() {
            _position = newPos;
            _isBoardLocked = true;
          });
          widget.onUserMove(mv, newPos.fen);
        }
      },
    );
  }
}
