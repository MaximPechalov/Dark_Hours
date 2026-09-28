class RunTracker {
  int kills = 0;
  int craftedCount = 0;
  int lootedCount = 0;
  int medicineUsed = 0;
  int itemsGiven = 0;
  int infections = 0;
  int sanityDaysLow = 0;
  int nightsSurvived = 0;
  int nightsPassed = 0;

  bool hadCombat = false;
  bool hadDamage = false;

  int lastCheckedDay = 0;
  int maxInventorySize = 0;
  bool alchemistCrafted = false;

  RunTracker();

  void reset() {
    kills = 0;
    craftedCount = 0;
    lootedCount = 0;
    medicineUsed = 0;
    itemsGiven = 0;
    infections = 0;
    sanityDaysLow = 0;
    nightsSurvived = 0;
    nightsPassed = 0;
    hadCombat = false;
    hadDamage = false;
    lastCheckedDay = 0;
    maxInventorySize = 0;
    alchemistCrafted = false;
  }

  /// Применить изменения к глобальной статистике
  void applyToStats(dynamic stats) {
    stats.totalKills += kills;
    stats.totalItemsCrafted += craftedCount;
    stats.totalItemsLooted += lootedCount;
    stats.totalMedicineUsed += medicineUsed;
    stats.totalItemsGivenToSurvivors += itemsGiven;
    stats.totalInfections += infections;
    stats.totalNights += nightsSurvived;
  }
}