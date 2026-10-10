import 'package:dark_hours/models/character/character_state.dart';

/// Логика определения состояния персонажа по его статам.
///
/// Приоритет состояний:
/// 1. `critical`  — health < 20 ИЛИ fatigue > 85
/// 2. `wounded`   — health < 50
/// 3. `hungry`    — hunger < 30
/// 4. `tired`     — fatigue > 60
/// 5. `normal`    — по умолчанию
///
/// Тяжёлое состояние приоритетнее лёгкого:
/// если игрок при смерти, он не должен видеть «просто уставший».
class CharacterStateCalculator {
  CharacterStateCalculator._();

  /// Пороги для состояний.
  static const int criticalHealthThreshold = 20;
  static const int criticalFatigueThreshold = 85;
  static const int woundedHealthThreshold = 50;
  static const int hungryHungerThreshold = 30;
  static const int tiredFatigueThreshold = 60;

  /// Определить состояние персонажа.
  static CharacterState compute({
    required int health,
    required int hunger,
    required int fatigue,
  }) {
    // При смерти — самое важное.
    if (health < criticalHealthThreshold ||
        fatigue > criticalFatigueThreshold) {
      return CharacterState.critical;
    }

    // Ранен.
    if (health < woundedHealthThreshold) {
      return CharacterState.wounded;
    }

    // Голоден.
    if (hunger < hungryHungerThreshold) {
      return CharacterState.hungry;
    }

    // Устал.
    if (fatigue > tiredFatigueThreshold) {
      return CharacterState.tired;
    }

    // Всё в порядке.
    return CharacterState.normal;
  }
}