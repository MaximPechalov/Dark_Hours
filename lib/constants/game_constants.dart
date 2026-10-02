/// Игровые константы — все магические числа в одном месте.
///
/// Здесь собраны значения, которые раньше были разбросаны по MapScreen.
/// Меняешь здесь — меняется везде.
class GameConstants {
  GameConstants._(); // нельзя создавать экземпляры

  // ═══════════════════════════════════════════════════════════
  // ВРЕМЯ (в минутах)
  // ═══════════════════════════════════════════════════════════

  /// Время на перемещение между локациями
  static const int moveTimeMinutes = 20;

  /// Время на один бой
  static const int combatTimeMinutes = 10;

  /// Время форсированного автосна (когда усталость критична)
  static const int forcedAutoSleepMinutes = 60;

  /// Время коллапса от истощения
  static const int collapseSleepMinutes = 240;

  /// Начальное игровое время (8:00 утра)
  static const int startTimeMinutes = 8 * 60;

  // ═══════════════════════════════════════════════════════════
  // СТОИМОСТЬ ДЕЙСТВИЙ (статы)
  // ═══════════════════════════════════════════════════════════

  /// Стамина на перемещение
  static const int moveStaminaCost = 5;

  /// Стамина на обыск локации
  static const int searchStaminaCost = 10;

  /// Усталость на обыск локации
  static const int searchFatigueCost = 8;

  /// Стамина на крафт предмета
  static const int craftStaminaCost = 5;

  /// Усталость на крафт предмета
  static const int craftFatigueCost = 5;

  /// Усталость за один шаг сюжета
  static const int storyFatiguePerStep = 2;

  /// Минимум стамины для крафта
  static const int minStaminaForCraft = 5;

  // ═══════════════════════════════════════════════════════════
  // ГРАНИЦЫ СТАТОВ
  // ═══════════════════════════════════════════════════════════

  /// Минимум и максимум всех статов (0-100)
  static const int minStat = 0;
  static const int maxStat = 100;

  /// Порог, при котором срабатывает автопредупреждение усталости
  static const int fatigueWarningThreshold = 80;

  /// Порог, при котором срабатывает форсированный автосон
  static const int fatigueForcedSleepThreshold = 95;

  /// Порог критической усталости — коллапс
  static const int fatigueCollapseThreshold = 100;

  /// Порог психики, ниже которого копится "стрессовый день"
  static const int sanityStressThreshold = 20;

  // ═══════════════════════════════════════════════════════════
  // ЭФФЕКТЫ СНА / КОЛЛАПСА
  // ═══════════════════════════════════════════════════════════

  /// После форсированного автосна
  static const int forcedAutoSleepFatigueReduce = 15;
  static const int forcedAutoSleepStaminaPenalty = 15;
  static const int forcedAutoSleepSanityPenalty = 5;

  /// После коллапса
  static const int collapseFatigueReset = 60;
  static const int collapseHealthPenalty = 20;
  static const int collapseSanityPenalty = 15;

  /// Шанс ограбления при коллапсе (в процентах)
  static const int collapseTheftChance = 30;

  /// Количество предметов, которые крадут при коллапсе
  static const int collapseTheftItems = 2;

  /// Шанс заболеть простудой после коллапса (в процентах)
  static const int collapseColdChance = 40;

  /// Максимальное количество часов между коллапсами (иначе смерть)
  static const int collapseRepeatHours = 24;

  // ═══════════════════════════════════════════════════════════
  // ОТДЫХ
  // ═══════════════════════════════════════════════════════════

  /// Порог опасности локации, при котором отдых "безопасен"
  static const int safeLocationDangerLevel = 3;

  /// Бонус к отдыху, если есть спальный мешок
  static const int sleepingBagStaminaBonus = 10;
  static const int sleepingBagSanityBonus = 10;

  /// Порог тепла, при котором риск простуды на отдыхе снижен
  static const int warmthColdResistThreshold = 40;

  /// Шанс простудиться при отдыхе в холоде (в процентах)
  static const int coldChanceLow = 10;   // если тепло
  static const int coldChanceHigh = 30;  // если холодно

  /// Длительность отдыха, при которой возможны ограбление/атака
  static const int restTheftMinDuration = 240;
  static const int restAttackMinDuration = 480;

  /// Шанс ограбления при отдыхе в опасной локации (в процентах)
  static const int restTheftChance = 25;

  /// Базовый шанс атаки при отдыхе (умножается на dangerMultiplier фазы суток)
  static const int restAttackBaseChance = 20;

  // ═══════════════════════════════════════════════════════════
  // БОЙ
  // ═══════════════════════════════════════════════════════════

  /// Максимальное здоровье игрока
  static const int playerMaxHealth = 100;

  /// Урон кулаками (если оружия нет)
  static const int fistsDamage = 3;

  /// Шанс встретить врага при обыске (1 из N)
  static const int enemyEncounterChance = 3;

  /// Имена "сюжетных боссов" — при поражении от них игрок умирает
  static const List<String> storyBosses = [
    'Васька',
    'Сергей',
    'Главарь банды',
  ];

  /// Имена "опасных" врагов — при поражении теряются 3 предмета
  static const List<String> dangerousEnemyKeywords = [
    'Бандит',
    'Дезертир',
    'Вооружённый',
    'Медведь',
    'Главарь',
  ];

  /// HP игрока после тяжёлого поражения
  static const int heavyDefeatHealth = 5;

  /// HP игрока после лёгкого поражения
  static const int lightDefeatHealth = 15;

  /// Сколько предметов теряется при тяжёлом поражении
  static const int heavyDefeatLostItems = 3;

  /// Сколько предметов теряется при лёгком поражении
  static const int lightDefeatLostItems = 2;

  /// Штрафы к психике после поражений
  static const int heavyDefeatSanityPenalty = 25;
  static const int lightDefeatSanityPenalty = 10;

  /// Штрафы к усталости после поражений
  static const int heavyDefeatFatigueGain = 40;
  static const int lightDefeatFatigueGain = 30;

  // ═══════════════════════════════════════════════════════════
  // ОБЫСК
  // ═══════════════════════════════════════════════════════════

  /// Базовый шанс заразиться от риска локации (risk в JSON)
  static const double locationRiskChance = 0.4;

  // ═══════════════════════════════════════════════════════════
  // АВТОСОХРАНЕНИЕ
  // ═══════════════════════════════════════════════════════════

  /// Периодичность автосохранения (в минутах игрового времени)
  static const int autosaveEveryMinutes = 5;

  // ═══════════════════════════════════════════════════════════
  // ГЛАВЫ
  // ═══════════════════════════════════════════════════════════

  /// Общее число дней в игре (после — зима)
  static const int totalDaysUntilWinter = 60;

  // ═══════════════════════════════════════════════════════════
  // ХАРАКТЕРИСТИКИ ПЕРСОНАЖЕЙ
  // ═══════════════════════════════════════════════════════════

  /// Характеристики по умолчанию
  static const int defaultIntelligence = 5;
  static const int defaultStrength = 5;

  /// Карта характеристик персонажей
  static const Map<String, Map<String, int>> characterStats = {
    'boris': {'intelligence': 5, 'strength': 7},
    'alina': {'intelligence': 4, 'strength': 3},
    'ivan': {'intelligence': 8, 'strength': 4},
    'andrey': {'intelligence': 9, 'strength': 2},
    'darya': {'intelligence': 7, 'strength': 4},
  };

  /// Получить статы персонажа по ID
  static Map<String, int> statsFor(String characterId) {
    return characterStats[characterId] ??
        {
          'intelligence': defaultIntelligence,
          'strength': defaultStrength,
        };
  }

  // ═══════════════════════════════════════════════════════════
  // ЦВЕТА (для UI)
  // ═══════════════════════════════════════════════════════════

  /// Основной "золотой" цвет интерфейса
  static const int primaryColorValue = 0xFFC8B464; // 200, 180, 100
  static const int backgroundColorValue = 0xFF0A0A0A; // 10, 10, 10
  static const int panelColorValue = 0xFF141414; // 20, 20, 20
  static const int cardColorValue = 0xFF121212; // 18, 18, 18

  // ═══════════════════════════════════════════════════════════
  // UI
  // ═══════════════════════════════════════════════════════════

  /// Максимальная высота панели предметов
  static const double maxPanelHeight = 480.0;

  /// Задержки анимаций
  static const int shortDelayMs = 100;
  static const int mediumDelayMs = 300;
  static const int longDelayMs = 600;

  /// Длительность снекбара по умолчанию (в секундах)
  static const int snackbarDefaultSeconds = 2;
  static const int snackbarLongSeconds = 4;
}