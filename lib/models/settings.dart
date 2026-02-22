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

  Map<String, dynamic> toJson() {
    return {
      'user_elo': userElo,
      'max_evaluation_strength': maxEvaluationStrength,
      'piece_set': pieceSet,
      'board_theme': boardTheme,
      'API_key': apiKey,
      'user_locale': userLocale,
      'model': model,
    };
  }
}

extension SettingsCopyWith on Settings {
  Settings copyWith({
    int? userElo,
    int? maxEvaluationStrength,
    String? pieceSet,
    String? boardTheme,
    String? apiKey,
    String? userLocale,
    String? model,
  }) {
    return Settings(
      userElo: userElo ?? this.userElo,
      maxEvaluationStrength: maxEvaluationStrength ?? this.maxEvaluationStrength,
      pieceSet: pieceSet ?? this.pieceSet,
      boardTheme: boardTheme ?? this.boardTheme,
      apiKey: apiKey ?? this.apiKey,
      userLocale: userLocale ?? this.userLocale,
      model: model ?? this.model,
    );
  }
}
