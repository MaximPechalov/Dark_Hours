import '../models/game_time.dart';

class TimeManager {
  /// Рассчитать расход голода/жажды за N минут
  /// Базовый расход: 1 единица голода за 20 минут
  /// Базовый расход: 1 единица жажды за 15 минут
  static Map<String, int> calculateConsumption({
    required int minutes,
    required TimePhase phase,
    required bool isSleeping,
  }) {
    final multiplier = phase.consumptionMultiplier;

    // Голод: 1 ед. за 20 мин × множитель
    final hungerLoss = isSleeping
        ? (minutes / 30 * multiplier).round()
        : (minutes / 20 * multiplier).round();

    // Жажда: 1 ед. за 15 мин × множитель
    final thirstLoss = isSleeping
        ? (minutes / 25 * multiplier).round()
        : (minutes / 15 * multiplier).round();

    // Усталость: 1 ед. за 30 мин × множитель (кроме сна)
    final fatigueGain = isSleeping
        ? 0
        : (minutes / 30 * multiplier).round();

    return {
      'hunger': -hungerLoss,
      'thirst': -thirstLoss,
      'fatigue': fatigueGain,
    };
  }

  /// Проверить штрафы за низкие ресурсы
  static List<String> getPenalties({
    required int hunger,
    required int thirst,
    required int stamina,
    required int sanity,
    required int fatigue,
  }) {
    final penalties = <String>[];

    if (hunger < 20) {
      penalties.add('🍞 Голод: -20% к силе действий');
    }
    if (hunger < 10) {
      penalties.add('💀 Истощение: -40% к силе действий');
    }
    if (thirst < 20) {
      penalties.add('💧 Жажда: -20% к вниманию');
    }
    if (thirst < 10) {
      penalties.add('👁 Галлюцинации: возможны ложные выборы');
    }
    if (stamina < 20) {
      penalties.add('⚡ Усталость: -30% к скорости');
    }
    if (sanity < 30) {
      penalties.add('🧠 Стресс: -20% к интеллекту');
    }
    if (sanity < 10) {
      penalties.add('😵 Психоз: галлюцинации');
    }
    if (fatigue > 80) {
      penalties.add('💤 Изнеможение: срочно нужен сон');
    }
    if (fatigue >= 100) {
      penalties.add('💀 Ты падаешь от усталости');
    }

    return penalties;
  }

  /// Проверить, нужен ли принудительный сон
  static bool needsForcedSleep(int fatigue) => fatigue >= 100;

  /// Стоит ли предупредить игрока
  static bool shouldWarn(int fatigue) => fatigue >= 80;

  /// Проверить критический голод/жажду
  static bool isCritical(int value) => value <= 5;
}