import 'package:flutter_test/flutter_test.dart';
import 'package:dark_hours/models/character/character.dart';

void main() {
  group('Character — статический список', () {
    test('содержит 5 персонажей', () {
      expect(Character.all.length, 5);
    });

    test('все id уникальны', () {
      final ids = Character.all.map((c) => c.id).toSet();
      expect(ids.length, 5);
    });

    test('getById возвращает персонажа', () {
      final boris = Character.getById('boris');
      expect(boris, isNotNull);
      expect(boris!.name, 'Борис');
    });

    test('getById возвращает null для несуществующего', () {
      expect(Character.getById('nonexistent'), isNull);
    });

    test('все персонажи имеют уникальные имена', () {
      final names = Character.all.map((c) => c.name).toSet();
      expect(names.length, 5);
    });
  });

  group('Character — характеристики', () {
    test('Алина самая выносливая', () {
      final alina = Character.getById('alina')!;
      final maxEndurance =
          Character.all.map((c) => c.endurance).reduce((a, b) => a > b ? a : b);
      expect(alina.endurance, maxEndurance);
    });

    test('Андрей самый умный', () {
      final andrey = Character.getById('andrey')!;
      final maxInt = Character.all
          .map((c) => c.intelligence)
          .reduce((a, b) => a > b ? a : b);
      expect(andrey.intelligence, maxInt);
    });
  });
}