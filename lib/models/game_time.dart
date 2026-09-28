import 'package:flutter/material.dart';

class GameTime {
  int totalMinutes;

  GameTime({required this.totalMinutes});

  /// День (1-60)
  int get day => (totalMinutes ~/ (24 * 60)) + 1;

  /// Час (0-23)
  int get hour => (totalMinutes ~/ 60) % 24;

  /// Минуты (0-59)
  int get minute => totalMinutes % 60;

  /// Фаза суток
  TimePhase get phase {
    final h = hour;
    if (h >= 5 && h < 11) return TimePhase.morning;
    if (h >= 11 && h < 17) return TimePhase.day;
    if (h >= 17 && h < 22) return TimePhase.evening;
    return TimePhase.night;
  }

  String get formatted {
    final hh = hour.toString().padLeft(2, '0');
    final mm = minute.toString().padLeft(2, '0');
    return 'День $day, $hh:$mm';
  }

  String get shortTime {
    final hh = hour.toString().padLeft(2, '0');
    final mm = minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  /// Сколько дней осталось до зимы (60 дней всего)
  int get daysUntilWinter => 60 - day;

  bool get isWinter => day > 60;

  void advance(int minutes) {
    totalMinutes += minutes;
  }

  static GameTime fromSave(int minutes) {
    return GameTime(totalMinutes: minutes);
  }
}

enum TimePhase {
  morning,
  day,
  evening,
  night,
}

extension TimePhaseExt on TimePhase {
  String get name {
    switch (this) {
      case TimePhase.morning:
        return 'Утро';
      case TimePhase.day:
        return 'День';
      case TimePhase.evening:
        return 'Вечер';
      case TimePhase.night:
        return 'Ночь';
    }
  }

  String get icon {
    switch (this) {
      case TimePhase.morning:
        return '🌅';
      case TimePhase.day:
        return '☀️';
      case TimePhase.evening:
        return '🌆';
      case TimePhase.night:
        return '🌙';
    }
  }

  Color get color {
    switch (this) {
      case TimePhase.morning:
        return const Color.fromARGB(255, 255, 200, 100);
      case TimePhase.day:
        return const Color.fromARGB(255, 255, 230, 150);
      case TimePhase.evening:
        return const Color.fromARGB(255, 200, 130, 80);
      case TimePhase.night:
        return const Color.fromARGB(255, 100, 100, 180);
    }
  }

  /// Множитель расхода голода/жажды
  double get consumptionMultiplier {
    switch (this) {
      case TimePhase.morning:
        return 1.0;
      case TimePhase.day:
        return 1.2;
      case TimePhase.evening:
        return 1.0;
      case TimePhase.night:
        return 0.6; // ночью меньше активности
    }
  }

  /// Множитель риска (для сна, перемещения)
  double get dangerMultiplier {
    switch (this) {
      case TimePhase.morning:
        return 0.8;
      case TimePhase.day:
        return 1.0;
      case TimePhase.evening:
        return 1.2;
      case TimePhase.night:
        return 1.8; // ночью опасно вдвойне
    }
  }
}