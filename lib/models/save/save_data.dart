class SaveData {
  final String characterId;
  final String characterName;
  final String currentNodeId;
  final String currentLocationId;
  final bool onMap;
  final int hunger;
  final int thirst;
  final int health;
  final int sanity;
  final int stamina;
  final int fatigue;
  final int timeMinutes;
  final int chapter;
  final List<String> history;
  final List<Map<String, dynamic>> inventoryItems;
  final Map<String, dynamic> equipmentItems;
  final List<Map<String, dynamic>> activeConditions;

  // НОВЫЕ ПОЛЯ
  final Map<String, int> searchedCounts;
  final List<String> unlockedLocations;

  final DateTime savedAt;

  SaveData({
    required this.characterId,
    required this.characterName,
    required this.currentNodeId,
    required this.currentLocationId,
    required this.onMap,
    required this.hunger,
    required this.thirst,
    required this.health,
    required this.sanity,
    required this.stamina,
    required this.fatigue,
    required this.timeMinutes,
    required this.chapter,
    required this.history,
    required this.inventoryItems,
    required this.equipmentItems,
    required this.activeConditions,
    Map<String, int>? searchedCounts,
    List<String>? unlockedLocations,
    required this.savedAt,
  })  : searchedCounts = searchedCounts ?? {},
        unlockedLocations = unlockedLocations ?? [];

  Map<String, dynamic> toJson() {
    return {
      'characterId': characterId,
      'characterName': characterName,
      'currentNodeId': currentNodeId,
      'currentLocationId': currentLocationId,
      'onMap': onMap,
      'hunger': hunger,
      'thirst': thirst,
      'health': health,
      'sanity': sanity,
      'stamina': stamina,
      'fatigue': fatigue,
      'timeMinutes': timeMinutes,
      'chapter': chapter,
      'history': history,
      'inventoryItems': inventoryItems,
      'equipmentItems': equipmentItems,
      'activeConditions': activeConditions,
      'searchedCounts': searchedCounts,
      'unlockedLocations': unlockedLocations,
      'savedAt': savedAt.toIso8601String(),
    };
  }

  factory SaveData.fromJson(Map<String, dynamic> json) {
    return SaveData(
      characterId: json['characterId'],
      characterName: json['characterName'],
      currentNodeId: json['currentNodeId'],
      currentLocationId: json['currentLocationId'] ?? 'home_boris',
      onMap: json['onMap'] ?? false,
      hunger: json['hunger'],
      thirst: json['thirst'],
      health: json['health'],
      sanity: json['sanity'],
      stamina: json['stamina'],
      fatigue: json['fatigue'] ?? 0,
      timeMinutes: json['timeMinutes'],
      chapter: json['chapter'],
      history: List<String>.from(json['history']),
      inventoryItems: List<Map<String, dynamic>>.from(
        (json['inventoryItems'] as List?) ?? [],
      ),
      equipmentItems: Map<String, dynamic>.from(
        (json['equipmentItems'] as Map?) ?? {},
      ),
      activeConditions: List<Map<String, dynamic>>.from(
        (json['activeConditions'] as List?) ?? [],
      ),
      searchedCounts: json['searchedCounts'] != null
          ? Map<String, int>.from(json['searchedCounts'])
          : {},
      unlockedLocations: json['unlockedLocations'] != null
          ? List<String>.from(json['unlockedLocations'])
          : [],
      savedAt: DateTime.parse(json['savedAt']),
    );
  }
}