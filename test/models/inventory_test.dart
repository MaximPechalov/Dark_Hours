import 'package:flutter_test/flutter_test.dart';
import 'package:dark_hours/models/inventory/inventory.dart';
import 'package:dark_hours/models/inventory/inventory_item.dart';

void main() {
  InventoryItem makeItem({
    required String id,
    double weight = 1.0,
    int count = 1,
  }) {
    return InventoryItem(
      id: id,
      name: id,
      icon: '📦',
      rarity: 'common',
      weight: weight,
      count: count,
      sourceType: 'resource',
    );
  }

  group('Inventory.addItem', () {
    test('добавляет новый предмет', () {
      final inv = Inventory(maxWeight: 100);
      final ok = inv.addItem(makeItem(id: 'wood'));
      expect(ok, true);
      expect(inv.items.length, 1);
    });

    test('стакает одинаковые предметы', () {
      final inv = Inventory(maxWeight: 100);
      inv.addItem(makeItem(id: 'wood', count: 1));
      inv.addItem(makeItem(id: 'wood', count: 2));
      expect(inv.items.length, 1);
      expect(inv.items.first.count, 3);
    });

    test('не добавляет при перегрузе', () {
      final inv = Inventory(maxWeight: 5);
      inv.addItem(makeItem(id: 'heavy', weight: 4.0));
      final ok = inv.addItem(makeItem(id: 'heavy2', weight: 4.0));
      expect(ok, false);
      expect(inv.items.length, 1);
    });
  });

  group('Inventory.removeItem', () {
    test('уменьшает count на 1', () {
      final inv = Inventory(maxWeight: 100);
      inv.addItem(makeItem(id: 'wood', count: 5));
      inv.removeItem('wood');
      expect(inv.items.first.count, 4);
    });

    test('удаляет предмет при count = 1', () {
      final inv = Inventory(maxWeight: 100);
      inv.addItem(makeItem(id: 'wood', count: 1));
      inv.removeItem('wood');
      expect(inv.items, isEmpty);
    });

    test('возвращает false для несуществующего', () {
      final inv = Inventory(maxWeight: 100);
      expect(inv.removeItem('nonexistent'), false);
    });
  });

  group('Inventory.hasItem', () {
    test('находит существующий предмет', () {
      final inv = Inventory(maxWeight: 100);
      inv.addItem(makeItem(id: 'wood'));
      expect(inv.hasItem('wood'), true);
    });

    test('false для несуществующего', () {
      final inv = Inventory(maxWeight: 100);
      expect(inv.hasItem('wood'), false);
    });
  });

  group('Inventory.countOf', () {
    test('возвращает count предмета', () {
      final inv = Inventory(maxWeight: 100);
      inv.addItem(makeItem(id: 'wood', count: 7));
      expect(inv.countOf('wood'), 7);
    });

    test('0 для несуществующего', () {
      final inv = Inventory(maxWeight: 100);
      expect(inv.countOf('wood'), 0);
    });
  });

  group('Inventory.currentWeight', () {
    test('суммирует вес всех предметов', () {
      final inv = Inventory(maxWeight: 100);
      inv.addItem(makeItem(id: 'a', weight: 2.0, count: 3));
      inv.addItem(makeItem(id: 'b', weight: 1.5, count: 2));
      // 2.0 * 3 + 1.5 * 2 = 6.0 + 3.0 = 9.0
      expect(inv.currentWeight, closeTo(9.0, 0.01));
    });

    test('0 для пустого инвентаря', () {
      final inv = Inventory(maxWeight: 100);
      expect(inv.currentWeight, 0);
    });
  });

  group('Inventory.isOverloaded', () {
    test('false при нормальном весе', () {
      final inv = Inventory(maxWeight: 10);
      inv.addItem(makeItem(id: 'wood', weight: 5.0));
      expect(inv.isOverloaded, false);
    });

    test('true при перегрузе', () {
      final inv = Inventory(maxWeight: 3);
      // Обходим проверку addItem — кладём напрямую
      inv.items.add(makeItem(id: 'heavy', weight: 5.0));
      expect(inv.isOverloaded, true);
    });
  });
}