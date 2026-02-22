import 'package:dartchess/dartchess.dart';
import 'package:flutter/widgets.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:chessground/chessground.dart' as cg;

const _pieceSetsPath = 'lib/piece_set';

/// A piece set and its corresponding piece assets.
enum PieceSet {
  maestro('Maestro', maestroAssets);

  const PieceSet(this.label, this.assets);

  /// The label of this [PieceSet].
  final String label;

  /// The [PieceAssets] for this [PieceSet].
  final cg.PieceAssets assets;

  /// The [PieceAssets] for the 'Maestro' piece set.
  static const maestroAssets = IMapConst({
    PieceKind.blackRook: AssetImage('$_pieceSetsPath/maestro/bR.png'),
    PieceKind.blackPawn: AssetImage('$_pieceSetsPath/maestro/bP.png'),
    PieceKind.blackKnight: AssetImage('$_pieceSetsPath/maestro/bN.png'),
    PieceKind.blackBishop: AssetImage('$_pieceSetsPath/maestro/bB.png'),
    PieceKind.blackQueen: AssetImage('$_pieceSetsPath/maestro/bQ.png'),
    PieceKind.blackKing: AssetImage('$_pieceSetsPath/maestro/bK.png'),
    PieceKind.whiteRook: AssetImage('$_pieceSetsPath/maestro/wR.png'),
    PieceKind.whitePawn: AssetImage('$_pieceSetsPath/maestro/wP.png'),
    PieceKind.whiteKnight: AssetImage('$_pieceSetsPath/maestro/wN.png'),
    PieceKind.whiteBishop: AssetImage('$_pieceSetsPath/maestro/wB.png'),
    PieceKind.whiteQueen: AssetImage('$_pieceSetsPath/maestro/wQ.png'),
    PieceKind.whiteKing: AssetImage('$_pieceSetsPath/maestro/wK.png'),
  });
}
