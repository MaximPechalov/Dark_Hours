import '../models/game_time.dart';

class TimeManager {
  /// Расход в 6 раз медленнее (шкалы 0-100)
  /// Игрок живёт днями, а не часами
  static Map<String, int> calculateConsumption({
    required int minutes,
    required TimePhase phase,
    required bool isSleeping,
  }) {
    final multiplier = phase.consumptionMultiplier;

    // Голод: 1 ед. / 120 мин × множитель (было /20)
    // Жажда: 1 ед. / 90 мин × множитель (было /15)
    // Усталость: 1 ед. / 90 мин × множитель (было /30)
    // Сон: расход ещё в 1.5 раза меньше

    final hungerLoss = isSleeping
        ? (minutes / 180 * multiplier).round()
        : (minutes / 120 * multiplier).round();

    final thirstLoss = isSleeping
        ? (minutes / 135 * multiplier).round()
        : (minutes / 90 * multiplier).round();

    final fatigueGain = isSleeping
        ? 0
        : (minutes / 90 * multiplier).round();

    return {
      'hunger': -hungerLoss,
      'thirst': -thirstLoss,
      'fatigue': fatigueGain,
    };
  }

  /// Штрафы при низких ресурсах (шкалы 0-100)
  static List<String> getPenalties({
    required int hunger,
    required int thirst,
    required int stamina,
    required int sanity,
    required int fatigue,
  }) {
    final penalties = <String>[];

    // ===== ГОЛОД =====
    if (hunger < 20) {
      penalties.add('🍞 Голод: -20% к силе действий');
    }
    if (hunger < 10) {
      penalties.add('💀 Истощение: -40% к силе действий');
    }

    // ===== ЖАЖДА =====
    if (thirst < 20) {
      penalties.add('💧 Жажда: -20% к вниманию');
    }
    if (thirst < 10) {
      penalties.add('👁 Галлюцинации: возможны ложные выборы');
    }

    // ===== ВЫНОСЛИВОСТЬ =====
    if (stamina < 20) {
      penalties.add('⚡ Усталость: -30% к скорости');
    }

    // ===== ПСИХИКА =====
    if (sanity < 30) {
      penalties.add('🧠 Стресс: -20% к интеллекту');
    }
    if (sanity < 10) {
      penalties.add('😵 Психоз: галлюцинации');
    }

    // ===== УСТАЛОСТЬ — 3 СТАДИИ =====
    if (fatigue >= 80 && fatigue < 95) {
      penalties.add('💤 Изнеможение: срочно нужен сон');
    }
    if (fatigue >= 95 && fatigue < 100) {
      penalties.add('⚠️ КРИТИЧНО: ты вот-вот упадёшь');
    }
    if (fatigue >= 100) {
      penalties.add('💀 Коллапс неизбежен');
    }

    // ===== БОНУС КОМФОРТА =====
    if (hunger > 50 && thirst > 50 && stamina > 50) {
      penalties.add('✨ Комфорт: +10% ко всем действиям');
    }

    return penalties;
  }

  static bool needsForcedSleep(int fatigue) => fatigue >= 100;

  static bool shouldWarn(int fatigue) => fatigue >= 80;

  static bool isCritical(int value) => value <= 5;

  /// Модификатор всех действий от состояния
  static double getActionMultiplier({
    required int hunger,
    required int thirst,
    required int stamina,
    required int sanity,
  }) {
    double multiplier = 1.0;

    // Голод
    if (hunger < 10) {
      multiplier -= 0.4;
    } else if (hunger < 20) {
      multiplier -= 0.2;
    }

    // Жажда
    if (thirst < 10) {
      multiplier -= 0.3;
    } else if (thirst < 20) {
      multiplier -= 0.1;
    }

    // Выносливость
    if (stamina < 20) {
      multiplier -= 0.3;
    }

    // Психика
    if (sanity < 10) {
      multiplier -= 0.3;
    } else if (sanity < 30) {
      multiplier -= 0.2;
    }

    // Бонус комфорта
    if (hunger > 50 && thirst > 50 && stamina > 50) {
      multiplier += 0.1;
    }

    return multiplier.clamp(0.3, 1.5);
  }
}