import 'package:flutter_test/flutter_test.dart';
import 'package:dark_hours/services/time/time_manager.dart';
import 'package:dark_hours/models/time/game_time.dart';

void main() {
  group('TimeManager.calculateConsumption', () {
    test('голод падает медленнее жажды (день, 600 мин)', () {
      final result = TimeManager.calculateConsumption(
        minutes: 600, // на длинном интервале видна разница
        phase: TimePhase.day,
        isSleeping: false,
      );

      final hunger = result['hunger']!.abs();
      final thirst = result['thirst']!.abs();

      expect(
        hunger,
        lessThan(thirst),
        reason: 'голод должен падать медленнее жажды',
      );
    });

    test('во сне расход меньше, чем в бодрствовании (ночь, 960 мин)', () {
      final awake = TimeManager.calculateConsumption(
        minutes: 960, // длинный интервал для видимой разницы
        phase: TimePhase.night,
        isSleeping: false,
      );
      final asleep = TimeManager.calculateConsumption(
        minutes: 960,
        phase: TimePhase.night,
        isSleeping: true,
      );

      expect(
        asleep['hunger']!.abs(),
        lessThan(awake['hunger']!.abs()),
        reason: 'во сне расход голода должен быть меньше',
      );
      expect(
        asleep['thirst']!.abs(),
        lessThan(awake['thirst']!.abs()),
        reason: 'во сне расход жажды должен быть меньше',
      );
    });

    test('во сне усталость не растёт', () {
      final asleep = TimeManager.calculateConsumption(
        minutes: 480,
        phase: TimePhase.night,
        isSleeping: true,
      );

      expect(asleep['fatigue'], 0);
    });

    test('ночью расход меньше, чем днём', () {
      final day = TimeManager.calculateConsumption(
        minutes: 600,
        phase: TimePhase.day,
        isSleeping: false,
      );
      final night = TimeManager.calculateConsumption(
        minutes: 600,
        phase: TimePhase.night,
        isSleeping: false,
      );

      expect(
        night['hunger']!.abs(),
        lessThan(day['hunger']!.abs()),
        reason: 'ночью расход должен быть меньше',
      );
    });

    test('все возвращаемые значения отрицательные для голода/жажды', () {
      final result = TimeManager.calculateConsumption(
        minutes: 60,
        phase: TimePhase.day,
        isSleeping: false,
      );

      expect(result['hunger']!, lessThanOrEqualTo(0));
      expect(result['thirst']!, lessThanOrEqualTo(0));
    });
  });

  group('TimeManager.getPenalties', () {
    test('при голоде ниже 20 выдаёт штраф', () {
      final penalties = TimeManager.getPenalties(
        hunger: 15,
        thirst: 100,
        stamina: 100,
        sanity: 100,
        fatigue: 0,
      );

      expect(
        penalties.any((p) => p.contains('Голод')),
        true,
        reason: 'должен быть штраф за голод',
      );
    });

    test('при голоде ниже 10 выдаёт критический штраф', () {
      final penalties = TimeManager.getPenalties(
        hunger: 5,
        thirst: 100,
        stamina: 100,
        sanity: 100,
        fatigue: 0,
      );

      expect(
        penalties.any((p) => p.contains('Истощение')),
        true,
      );
    });

    test('при полном комфорте выдаёт бонус', () {
      final penalties = TimeManager.getPenalties(
        hunger: 80,
        thirst: 80,
        stamina: 80,
        sanity: 80,
        fatigue: 0,
      );

      expect(
        penalties.any((p) => p.contains('Комфорт')),
        true,
        reason: 'при высоких статах должен быть бонус',
      );
    });

    test('при всех 100 — только бонус, без штрафов', () {
      final penalties = TimeManager.getPenalties(
        hunger: 100,
        thirst: 100,
        stamina: 100,
        sanity: 100,
        fatigue: 0,
      );

      // Бонус есть
      expect(penalties.any((p) => p.contains('Комфорт')), true);
      // Штрафов нет
      expect(penalties.any((p) => p.contains('Голод')), false);
      expect(penalties.any((p) => p.contains('Жажда')), false);
      expect(penalties.any((p) => p.contains('Истощение')), false);
    });

    test('при усталости 85 выдаёт изнеможение', () {
      final penalties = TimeManager.getPenalties(
        hunger: 100,
        thirst: 100,
        stamina: 100,
        sanity: 100,
        fatigue: 85,
      );

      expect(
        penalties.any((p) => p.contains('Изнеможение')),
        true,
      );
    });

    test('при усталости 100 выдаёт коллапс', () {
      final penalties = TimeManager.getPenalties(
        hunger: 100,
        thirst: 100,
        stamina: 100,
        sanity: 100,
        fatigue: 100,
      );

      expect(
        penalties.any((p) => p.contains('Коллапс')),
        true,
      );
    });
  });

  group('TimeManager.getActionMultiplier', () {
    test('при полном комфорте множитель 1.1', () {
      final mult = TimeManager.getActionMultiplier(
        hunger: 80,
        thirst: 80,
        stamina: 80,
        sanity: 80,
      );

      expect(mult, closeTo(1.1, 0.01));
    });

    test('при критическом голоде множитель снижен', () {
      final mult = TimeManager.getActionMultiplier(
        hunger: 5,
        thirst: 80,
        stamina: 80,
        sanity: 80,
      );

      expect(mult, lessThan(1.0));
    });

    test('множитель не ниже 0.3', () {
      final mult = TimeManager.getActionMultiplier(
        hunger: 0,
        thirst: 0,
        stamina: 0,
        sanity: 0,
      );

      expect(mult, greaterThanOrEqualTo(0.3));
    });

    test('множитель не выше 1.5', () {
      final mult = TimeManager.getActionMultiplier(
        hunger: 100,
        thirst: 100,
        stamina: 100,
        sanity: 100,
      );

      expect(mult, lessThanOrEqualTo(1.5));
    });
  });
}