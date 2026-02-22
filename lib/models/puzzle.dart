class Puzzle {
  final int id;
  final String fen;
  final String lastMove;
  final int userColor;

  Puzzle({
    required this.id,
    required this.fen,
    required this.lastMove,
    required this.userColor,
  });

  factory Puzzle.fromJson(Map<String, dynamic> json, int id) {
    return Puzzle(
      id: id,
      fen: json['fen'] as String,
      lastMove: json['last_move'] as String,
      userColor: json['user_color'] as int,
    );
  }
}

class PuzzleList {
  final List<int> ids;

  PuzzleList({required this.ids});

  factory PuzzleList.fromJson(List<dynamic> json) {
    return PuzzleList(
      ids: json.map((id) => id as int).toList(),
    );
  }
}
