class PlayerStats {
  // Общая статистика
  int totalGamesPlayed;
  int totalDeaths;
  int totalDaysSurvived;
  int bestRunDays;
  String bestRunCharacter;
  int totalKills;
  int totalItemsCrafted;
  int totalItemsLooted;
  int totalMedicineUsed;
  int totalItemsGivenToSurvivors;
  int totalNights;
  int totalInfections;

  // Разблокированные достижения
  Set<String> unlockedAchievements;

  // Игроки, за которых играли
  Set<String> playedCharacters;

  PlayerStats({
    this.totalGamesPlayed = 0,
    this.totalDeaths = 0,
    this.totalDaysSurvived = 0,
    this.bestRunDays = 0,
    this.bestRunCharacter = '',
    this.totalKills = 0,
    this.totalItemsCrafted = 0,
    this.totalItemsLooted = 0,
    this.totalMedicineUsed = 0,
    this.totalItemsGivenToSurvivors = 0,
    this.totalNights = 0,
    this.totalInfections = 0,
    Set<String>? unlockedAchievements,
    Set<String>? playedCharacters,
  })  : unlockedAchievements = unlockedAchievements ?? {},
        playedCharacters = playedCharacters ?? {};

  Map<String, dynamic> toJson() {
    return {
      'totalGamesPlayed': totalGamesPlayed,
      'totalDeaths': totalDeaths,
      'totalDaysSurvived': totalDaysSurvived,
      'bestRunDays': bestRunDays,
      'bestRunCharacter': bestRunCharacter,
      'totalKills': totalKills,
      'totalItemsCrafted': totalItemsCrafted,
      'totalItemsLooted': totalItemsLooted,
      'totalMedicineUsed': totalMedicineUsed,
      'totalItemsGivenToSurvivors': totalItemsGivenToSurvivors,
      'totalNights': totalNights,
      'totalInfections': totalInfections,
      'unlockedAchievements': unlockedAchievements.toList(),
      'playedCharacters': playedCharacters.toList(),
    };
  }

  factory PlayerStats.fromJson(Map<String, dynamic> json) {
    return PlayerStats(
      totalGamesPlayed: json['totalGamesPlayed'] ?? 0,
      totalDeaths: json['totalDeaths'] ?? 0,
      totalDaysSurvived: json['totalDaysSurvived'] ?? 0,
      bestRunDays: json['bestRunDays'] ?? 0,
      bestRunCharacter: json['bestRunCharacter'] ?? '',
      totalKills: json['totalKills'] ?? 0,
      totalItemsCrafted: json['totalItemsCrafted'] ?? 0,
      totalItemsLooted: json['totalItemsLooted'] ?? 0,
      totalMedicineUsed: json['totalMedicineUsed'] ?? 0,
      totalItemsGivenToSurvivors: json['totalItemsGivenToSurvivors'] ?? 0,
      totalNights: json['totalNights'] ?? 0,
      totalInfections: json['totalInfections'] ?? 0,
      unlockedAchievements: Set<String>.from(
        json['unlockedAchievements'] ?? [],
      ),
      playedCharacters: Set<String>.from(json['playedCharacters'] ?? []),
    );
  }
}