// test/constants/game_constants_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:dark_hours/constants/game_constants.dart';

void main() {
  // ═══════════════════════════════════════════════════════════
  // СТАТЫ ПЕРСОНАЖЕЙ
  // ═══════════════════════════════════════════════════════════

  group('GameConstants.statsFor', () {
    test('возвращает статы для boris', () {
      final stats = GameConstants.statsFor('boris');
      expect(stats['intelligence'], 5);
      expect(stats['strength'], 7);
      expect(stats['cunning'], 4);
      expect(stats['endurance'], 6);
    });

    test('возвращает статы для alina', () {
      final stats = GameConstants.statsFor('alina');
      expect(stats['intelligence'], 4);
      expect(stats['strength'], 3);
      expect(stats['cunning'], 6);
      expect(stats['endurance'], 9);
    });

    test('возвращает статы для ivan', () {
      final stats = GameConstants.statsFor('ivan');
      expect(stats['intelligence'], 8);
      expect(stats['strength'], 4);
      expect(stats['cunning'], 8);
      expect(stats['endurance'], 3);
    });

    test('возвращает статы для andrey', () {
      final stats = GameConstants.statsFor('andrey');
      expect(stats['intelligence'], 9);
      expect(stats['strength'], 2);
      expect(stats['cunning'], 4);
      expect(stats['endurance'], 4);
    });

    test('возвращает статы для darya', () {
      final stats = GameConstants.statsFor('darya');
      expect(stats['intelligence'], 7);
      expect(stats['strength'], 4);
      expect(stats['cunning'], 6);
      expect(stats['endurance'], 6);
    });

    test('возвращает дефолтные статы для неизвестного персонажа', () {
      final stats = GameConstants.statsFor('nonexistent');
      expect(stats['intelligence'], GameConstants.defaultIntelligence);
      expect(stats['strength'], GameConstants.defaultStrength);
      expect(stats['cunning'], GameConstants.defaultCunning);
      expect(stats['endurance'], GameConstants.defaultEndurance);
    });
  });

  group('GameConstants.cunningFor / enduranceFor', () {
    test('cunningFor возвращает правильное значение', () {
      expect(GameConstants.cunningFor('boris'), 4);
      expect(GameConstants.cunningFor('alina'), 6);
      expect(GameConstants.cunningFor('ivan'), 8);
      expect(GameConstants.cunningFor('andrey'), 4);
      expect(GameConstants.cunningFor('darya'), 6);
    });

    test('enduranceFor возвращает правильное значение', () {
      expect(GameConstants.enduranceFor('boris'), 6);
      expect(GameConstants.enduranceFor('alina'), 9);
      expect(GameConstants.enduranceFor('ivan'), 3);
      expect(GameConstants.enduranceFor('andrey'), 4);
      expect(GameConstants.enduranceFor('darya'), 6);
    });

    test('cunningFor возвращает дефолт для неизвестного', () {
      expect(
        GameConstants.cunningFor('nonexistent'),
        GameConstants.defaultCunning,
      );
    });

    test('enduranceFor возвращает дефолт для неизвестного', () {
      expect(
        GameConstants.enduranceFor('nonexistent'),
        GameConstants.defaultEndurance,
      );
    });
  });

  // ═══════════════════════════════════════════════════════════
  // CUNNING — УКЛОНЕНИЕ
  // ═══════════════════════════════════════════════════════════

  group('GameConstants.cunningDodgeBonus', () {
    test('cunning 5 (baseStat) → 0', () {
      expect(GameConstants.cunningDodgeBonus(5), 0.0);
    });

    test('cunning 8 → +0.09 (3 * 0.03)', () {
      expect(GameConstants.cunningDodgeBonus(8), closeTo(0.09, 0.001));
    });

    test('cunning 10 → клампится к max 0.15', () {
      expect(GameConstants.cunningDodgeBonus(10), 0.15);
    });

    test('cunning 1 → клампится к min -0.10', () {
      expect(GameConstants.cunningDodgeBonus(1), -0.10);
    });

    test('cunning 3 → штраф -0.06 (2 пункта ниже базы * 0.03)', () {
      expect(GameConstants.cunningDodgeBonus(3), closeTo(-0.06, 0.001));
    });

    test('cunning 6 → +0.03', () {
      expect(GameConstants.cunningDodgeBonus(6), closeTo(0.03, 0.001));
    });

    test('cunning 4 → -0.03', () {
      expect(GameConstants.cunningDodgeBonus(4), closeTo(-0.03, 0.001));
    });
  });

  // ═══════════════════════════════════════════════════════════
  // CUNNING — РАЗВЕДКА
  // ═══════════════════════════════════════════════════════════

  group('GameConstants.cunningScoutBonus', () {
    test('cunning 5 → 0', () {
      expect(GameConstants.cunningScoutBonus(5), 0);
    });

    test('cunning 8 → +3 локации', () {
      expect(GameConstants.cunningScoutBonus(8), 3);
    });

    test('cunning 10 → клампится к max 5', () {
      expect(GameConstants.cunningScoutBonus(10), 5);
    });

    test('cunning 3 → 0 (кламп снизу, штрафа нет)', () {
      expect(GameConstants.cunningScoutBonus(3), 0);
    });

    test('cunning 4 → 0 (штрафа нет)', () {
      expect(GameConstants.cunningScoutBonus(4), 0);
    });

    test('cunning 6 → +1 локация', () {
      expect(GameConstants.cunningScoutBonus(6), 1);
    });
  });

  // ═══════════════════════════════════════════════════════════
  // CUNNING — ПОБЕГ
  // ═══════════════════════════════════════════════════════════

  group('GameConstants.cunningFleeBonus', () {
    test('cunning 5 → 0', () {
      expect(GameConstants.cunningFleeBonus(5), 0.0);
    });

    test('cunning 8 → +0.12 (3 * 0.04)', () {
      expect(GameConstants.cunningFleeBonus(8), closeTo(0.12, 0.001));
    });

    test('cunning 10 → клампится к max 0.20', () {
      expect(GameConstants.cunningFleeBonus(10), 0.20);
    });

    test('cunning 3 → 0 (штрафа нет, flee всегда ≥ 0)', () {
      expect(GameConstants.cunningFleeBonus(3), 0.0);
    });

    test('cunning 1 → 0 (штрафа нет)', () {
      expect(GameConstants.cunningFleeBonus(1), 0.0);
    });
  });

  // ═══════════════════════════════════════════════════════════
  // CUNNING — ВРЕМЯ КРАФТА
  // ═══════════════════════════════════════════════════════════

  group('GameConstants.cunningCraftTimeSave', () {
    test('cunning 5 → 0', () {
      expect(GameConstants.cunningCraftTimeSave(5), 0);
    });

    test('cunning 8 → -3 минуты', () {
      expect(GameConstants.cunningCraftTimeSave(8), 3);
    });

    test('cunning 10 → клампится к max 5', () {
      expect(GameConstants.cunningCraftTimeSave(10), 5);
    });

    test('cunning 3 → 0 (штрафа нет)', () {
      expect(GameConstants.cunningCraftTimeSave(3), 0);
    });

    test('cunning 6 → -1 минута', () {
      expect(GameConstants.cunningCraftTimeSave(6), 1);
    });
  });

  // ═══════════════════════════════════════════════════════════
  // ENDURANCE — СТОИМОСТЬ ПЕРЕМЕЩЕНИЯ
  // ═══════════════════════════════════════════════════════════

  group('GameConstants.enduranceMoveMultiplier', () {
    test('endurance 5 (baseStat) → 1.0 (база)', () {
      expect(GameConstants.enduranceMoveMultiplier(5), closeTo(1.0, 0.001));
    });

    test('endurance 9 → 0.80 (на 20% дешевле)', () {
      expect(GameConstants.enduranceMoveMultiplier(9), closeTo(0.80, 0.001));
    });

    test('endurance 10 → клампится к 0.75', () {
      expect(GameConstants.enduranceMoveMultiplier(10), 0.75);
    });

    test('endurance 3 → 1.10 (на 10% дороже)', () {
      expect(GameConstants.enduranceMoveMultiplier(3), closeTo(1.10, 0.001));
    });

    test('endurance 1 → клампится к 1.20 (максимум +20%)', () {
      expect(GameConstants.enduranceMoveMultiplier(1), 1.20);
    });

    test('endurance 6 → 0.95 (на 5% дешевле)', () {
      expect(GameConstants.enduranceMoveMultiplier(6), closeTo(0.95, 0.001));
    });
  });

  // ═══════════════════════════════════════════════════════════
  // ENDURANCE — ОТДЫХ
  // ═══════════════════════════════════════════════════════════

  group('GameConstants.enduranceRestBonus', () {
    test('endurance 5 → 0', () {
      expect(GameConstants.enduranceRestBonus(5), 0);
    });

    test('endurance 9 → +8 (4 * 2)', () {
      expect(GameConstants.enduranceRestBonus(9), 8);
    });

    test('endurance 10 → клампится к max 10', () {
      expect(GameConstants.enduranceRestBonus(10), 10);
    });

    test('endurance 1 → клампится к min -6', () {
      expect(GameConstants.enduranceRestBonus(1), -6);
    });

    test('endurance 3 → -4 ((3-5)*2)', () {
      expect(GameConstants.enduranceRestBonus(3), -4);
    });

    test('endurance 6 → +2', () {
      expect(GameConstants.enduranceRestBonus(6), 2);
    });

    test('endurance 2 → клампится к min -6', () {
      expect(GameConstants.enduranceRestBonus(2), -6);
    });
  });

  // ═══════════════════════════════════════════════════════════
  // ENDURANCE — ПОБЕГ
  // ═══════════════════════════════════════════════════════════

  group('GameConstants.enduranceFleeBonus', () {
    test('endurance 5 → 0', () {
      expect(GameConstants.enduranceFleeBonus(5), 0.0);
    });

    test('endurance 9 → +0.16 (4 * 0.04)', () {
      expect(GameConstants.enduranceFleeBonus(9), closeTo(0.16, 0.001));
    });

    test('endurance 10 → клампится к max 0.20', () {
      expect(GameConstants.enduranceFleeBonus(10), 0.20);
    });

    test('endurance 3 → 0 (штрафа нет)', () {
      expect(GameConstants.enduranceFleeBonus(3), 0.0);
    });

    test('endurance 6 → +0.04', () {
      expect(GameConstants.enduranceFleeBonus(6), closeTo(0.04, 0.001));
    });
  });

  // ═══════════════════════════════════════════════════════════
  // ENDURANCE — УСТАЛОСТЬ
  // ═══════════════════════════════════════════════════════════

  group('GameConstants.enduranceFatigueMultiplier', () {
    test('endurance 5 → 1.0', () {
      expect(
        GameConstants.enduranceFatigueMultiplier(5),
        closeTo(1.0, 0.001),
      );
    });

    test('endurance 9 → 0.80 (на 20% меньше усталости)', () {
      expect(
        GameConstants.enduranceFatigueMultiplier(9),
        closeTo(0.80, 0.001),
      );
    });

    test('endurance 10 → клампится к 0.75', () {
      expect(GameConstants.enduranceFatigueMultiplier(10), 0.75);
    });

    test('endurance 1 → клампится к 1.10 (максимум +10%)', () {
      expect(GameConstants.enduranceFatigueMultiplier(1), 1.10);
    });

    test('endurance 3 → 1.10 (штраф +10%)', () {
      expect(
        GameConstants.enduranceFatigueMultiplier(3),
        closeTo(1.10, 0.001),
      );
    });
  });

  // ═══════════════════════════════════════════════════════════
  // ИНТЕГРАЦИОННЫЕ ПРОВЕРКИ
  // ═══════════════════════════════════════════════════════════

  group('Сравнение персонажей по формулам', () {
    test('Иван (cunning 8) уклоняется лучше Бориса (cunning 4)', () {
      final ivanDodge = GameConstants.cunningDodgeBonus(8);
      final borisDodge = GameConstants.cunningDodgeBonus(4);
      expect(ivanDodge, greaterThan(borisDodge));
    });

    test('Иван (cunning 8) разведывает больше Бориса (cunning 4)', () {
      final ivanScout = GameConstants.cunningScoutBonus(8);
      final borisScout = GameConstants.cunningScoutBonus(4);
      expect(ivanScout, greaterThan(borisScout));
    });

    test('Алина (endurance 9) бегает дешевле Ивана (endurance 3)', () {
      final alina = GameConstants.enduranceMoveMultiplier(9);
      final ivan = GameConstants.enduranceMoveMultiplier(3);
      expect(alina, lessThan(ivan));
    });

    test('Алина (endurance 9) лучше убегает, чем Борис (endurance 6)', () {
      final alina = GameConstants.enduranceFleeBonus(9);
      final boris = GameConstants.enduranceFleeBonus(6);
      expect(alina, greaterThan(boris));
    });

    test('Иван (cunning 8) крафтит быстрее Андрея (cunning 4)', () {
      final ivan = GameConstants.cunningCraftTimeSave(8);
      final andrey = GameConstants.cunningCraftTimeSave(4);
      expect(ivan, greaterThan(andrey));
    });

    test('Алина (endurance 9) устаёт медленнее Ивана (endurance 3)', () {
      final alina = GameConstants.enduranceFatigueMultiplier(9);
      final ivan = GameConstants.enduranceFatigueMultiplier(3);
      expect(alina, lessThan(ivan));
    });

    test('Алина (endurance 9) восстанавливается лучше Ивана (3) на отдыхе',
        () {
      final alina = GameConstants.enduranceRestBonus(9);
      final ivan = GameConstants.enduranceRestBonus(3);
      expect(alina, greaterThan(ivan));
    });
  });

  group('Границы и клампы', () {
    test('cunningDodgeBonus всегда в [-0.10, 0.15]', () {
      for (int c = 0; c <= 10; c++) {
        final v = GameConstants.cunningDodgeBonus(c);
        expect(v, greaterThanOrEqualTo(GameConstants.cunningDodgeMin));
        expect(v, lessThanOrEqualTo(GameConstants.cunningDodgeMax));
      }
    });

    test('cunningScoutBonus всегда в [0, 5]', () {
      for (int c = 0; c <= 10; c++) {
        final v = GameConstants.cunningScoutBonus(c);
        expect(v, greaterThanOrEqualTo(0));
        expect(v, lessThanOrEqualTo(GameConstants.cunningScoutMax));
      }
    });

    test('cunningFleeBonus всегда в [0, 0.20]', () {
      for (int c = 0; c <= 10; c++) {
        final v = GameConstants.cunningFleeBonus(c);
        expect(v, greaterThanOrEqualTo(0.0));
        expect(v, lessThanOrEqualTo(GameConstants.cunningFleeMax));
      }
    });

    test('cunningCraftTimeSave всегда в [0, 5]', () {
      for (int c = 0; c <= 10; c++) {
        final v = GameConstants.cunningCraftTimeSave(c);
        expect(v, greaterThanOrEqualTo(0));
        expect(v, lessThanOrEqualTo(GameConstants.cunningCraftTimeSaveMax));
      }
    });

    test('enduranceMoveMultiplier всегда в [0.75, 1.20]', () {
      final minMult = 1.0 - GameConstants.enduranceMoveCostMaxSave;
      final maxMult = 1.0 + GameConstants.enduranceMoveCostMaxPenalty;
      for (int e = 0; e <= 10; e++) {
        final v = GameConstants.enduranceMoveMultiplier(e);
        expect(v, greaterThanOrEqualTo(minMult - 0.001));
        expect(v, lessThanOrEqualTo(maxMult + 0.001));
      }
    });

    test('enduranceRestBonus всегда в [-6, 10]', () {
      for (int e = 0; e <= 10; e++) {
        final v = GameConstants.enduranceRestBonus(e);
        expect(v, greaterThanOrEqualTo(GameConstants.enduranceRestBonusMin));
        expect(v, lessThanOrEqualTo(GameConstants.enduranceRestBonusMax));
      }
    });

    test('enduranceFleeBonus всегда в [0, 0.20]', () {
      for (int e = 0; e <= 10; e++) {
        final v = GameConstants.enduranceFleeBonus(e);
        expect(v, greaterThanOrEqualTo(0.0));
        expect(v, lessThanOrEqualTo(GameConstants.enduranceFleeMax));
      }
    });

    test('enduranceFatigueMultiplier всегда в [0.75, 1.10]', () {
      final minMult = 1.0 - GameConstants.enduranceFatigueResistMax;
      final maxMult = 1.0 - GameConstants.enduranceFatigueResistMin;
      for (int e = 0; e <= 10; e++) {
        final v = GameConstants.enduranceFatigueMultiplier(e);
        expect(v, greaterThanOrEqualTo(minMult - 0.001));
        expect(v, lessThanOrEqualTo(maxMult + 0.001));
      }
    });
  });
}