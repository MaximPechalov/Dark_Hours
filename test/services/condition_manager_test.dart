import 'package:flutter_test/flutter_test.dart';
import 'package:dark_hours/models/conditions/condition.dart';
import 'package:dark_hours/models/conditions/active_condition.dart';
import 'package:dark_hours/services/conditions/condition_manager.dart';

void main() {
  // Тестовые состояния
  const infection = Condition(
    id: 'infection',
    name: 'Инфекция',
    description: 'Рана заражена',
    icon: '🦠',
    severity: 'medium',
    effectsPerTurn: {'health': -3, 'stamina': -1},
    cureItems: ['antibiotic_pill'],
    cureChance: 0.9,
    durationDays: 5,
    source: ['combat_wound'],
  );

  const cold = Condition(
    id: 'cold',
    name: 'Простуда',
    description: 'Промок и замёрз',
    icon: '🤧',
    severity: 'low',
    effectsPerTurn: {'health': -1, 'stamina': -2},
    cureItems: ['herb_medkit'],
    cureChance: 0.8,
    durationDays: 4,
    source: ['cold_weather'],
  );

  const bleeding = Condition(
    id: 'bleeding',
    name: 'Кровотечение',
    description: 'Сильная рана',
    icon: '🩸',
    severity: 'critical',
    effectsPerTurn: {'health': -8, 'stamina': -3},
    cureItems: ['bandage'],
    cureChance: 1.0,
    durationDays: 1,
    source: ['combat_wound'],
  );

  group('ConditionManager.applyEffects', () {
    test('суммирует эффекты всех болезней', () {
      final active = [
        ActiveCondition(condition: infection, daysRemaining: 5),
        ActiveCondition(condition: cold, daysRemaining: 4),
      ];

      final result = ConditionManager.applyEffects(active);

      // infection: health -3, stamina -1
      // cold: health -1, stamina -2
      // Итого: health -4, stamina -3
      expect(result['health'], -4);
      expect(result['stamina'], -3);
    });

    test('единственная болезнь выдаёт свои эффекты', () {
      final active = [
        ActiveCondition(condition: bleeding, daysRemaining: 1),
      ];

      final result = ConditionManager.applyEffects(active);

      expect(result['health'], -8);
      expect(result['stamina'], -3);
    });

    test('пустой список даёт пустой результат', () {
      final result = ConditionManager.applyEffects([]);
      expect(result, isEmpty);
    });
  });

  group('ConditionManager.tryInfect', () {
    test('при chance = 1.0 всегда заражает', () {
      // Ищем хотя бы раз из 20 попыток
      final allConditions = [infection, cold, bleeding];
      int infected = 0;
      for (int i = 0; i < 20; i++) {
        final result = ConditionManager.tryInfect(
          allConditions,
          'combat_wound',
          1.0,
        );
        if (result != null) infected++;
      }
      expect(infected, 20);
    });

    test('при chance = 0.0 никогда не заражает', () {
      final allConditions = [infection, cold, bleeding];
      for (int i = 0; i < 20; i++) {
        final result = ConditionManager.tryInfect(
          allConditions,
          'combat_wound',
          0.0,
        );
        expect(result, isNull);
      }
    });

    test('возвращает только болезни с подходящим source', () {
      final allConditions = [infection, cold, bleeding];
      // combat_wound есть только у infection и bleeding
      for (int i = 0; i < 10; i++) {
        final result = ConditionManager.tryInfect(
          allConditions,
          'combat_wound',
          1.0,
        );
        expect(result, isNotNull);
        expect(
          ['infection', 'bleeding'],
          contains(result!.id),
        );
      }
    });

    test('возвращает null, если нет болезней с этим source', () {
      final allConditions = [infection, cold, bleeding];
      final result = ConditionManager.tryInfect(
        allConditions,
        'nonexistent_source',
        1.0,
      );
      expect(result, isNull);
    });
  });

  group('ConditionManager.hasCondition', () {
    test('находит существующее состояние', () {
      final active = [
        ActiveCondition(condition: infection, daysRemaining: 5),
      ];
      expect(ConditionManager.hasCondition(active, 'infection'), true);
    });

    test('возвращает false для отсутствующего', () {
      final active = [
        ActiveCondition(condition: infection, daysRemaining: 5),
      ];
      expect(ConditionManager.hasCondition(active, 'cold'), false);
    });

    test('работает с пустым списком', () {
      expect(ConditionManager.hasCondition([], 'infection'), false);
    });
  });

  group('ConditionManager.tryCure', () {
    test('возвращает false для неподходящего предмета', () {
      final ac = ActiveCondition(condition: infection, daysRemaining: 5);
      // bandage не подходит для infection
      expect(ConditionManager.tryCure(ac, 'bandage'), false);
    });

    test('с chance = 1.0 всегда лечит подходящим предметом', () {
      final ac = ActiveCondition(condition: bleeding, daysRemaining: 1);
      // cureChance = 1.0
      expect(ConditionManager.tryCure(ac, 'bandage'), true);
    });
  });

  group('ConditionManager.tickDay', () {
    test('уменьшает daysRemaining на 1', () {
      final active = [
        ActiveCondition(condition: infection, daysRemaining: 5),
      ];
      final result = ConditionManager.tickDay(active);
      expect(result.length, 1);
      expect(result.first.daysRemaining, 4);
    });

    test('удаляет болезни с daysRemaining = 0', () {
      final active = [
        ActiveCondition(condition: bleeding, daysRemaining: 1),
      ];
      final result = ConditionManager.tickDay(active);
      expect(result, isEmpty);
    });

    test('работает с несколькими состояниями', () {
      final active = [
        ActiveCondition(condition: infection, daysRemaining: 5),
        ActiveCondition(condition: bleeding, daysRemaining: 1),
        ActiveCondition(condition: cold, daysRemaining: 3),
      ];
      final result = ConditionManager.tickDay(active);
      expect(result.length, 2);
      expect(result.any((c) => c.condition.id == 'infection'), true);
      expect(result.any((c) => c.condition.id == 'cold'), true);
      expect(result.any((c) => c.condition.id == 'bleeding'), false);
    });
  });
}