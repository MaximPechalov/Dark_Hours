import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dark_hours/models/save/save_data.dart';
import 'package:dark_hours/services/save/save_manager.dart';

void main() {
  setUp(() async {
    // Очищаем SharedPreferences перед каждым тестом
    SharedPreferences.setMockInitialValues({});
  });

  SaveData makeSave({
    String characterId = 'boris',
    String characterName = 'Борис',
    int chapter = 1,
  }) {
    return SaveData(
      characterId: characterId,
      characterName: characterName,
      currentNodeId: 'map',
      currentLocationId: 'home_boris',
      onMap: true,
      hunger: 80,
      thirst: 70,
      health: 90,
      sanity: 85,
      stamina: 75,
      fatigue: 10,
      timeMinutes: 600,
      chapter: chapter,
      history: ['flag1', 'flag2'],
      inventoryItems: [],
      equipmentItems: {},
      activeConditions: [],
      savedAt: DateTime.now(),
    );
  }

  group('SaveManager.save + load', () {
    test('сохраняет и загружает прогресс', () async {
      final save = makeSave();
      final ok = await SaveManager.save(save);
      expect(ok, true);

      final loaded = await SaveManager.load();
      expect(loaded, isNotNull);
      expect(loaded!.characterId, 'boris');
      expect(loaded.hunger, 80);
      expect(loaded.thirst, 70);
    });

    test('load возвращает null, если сохранения нет', () async {
      final loaded = await SaveManager.load();
      expect(loaded, isNull);
    });

    test('сохраняет chapter', () async {
      await SaveManager.save(makeSave(chapter: 3));
      final loaded = await SaveManager.load();
      expect(loaded!.chapter, 3);
    });

    test('сохраняет флаги', () async {
      await SaveManager.save(makeSave());
      final loaded = await SaveManager.load();
      expect(loaded!.history, contains('flag1'));
      expect(loaded.history, contains('flag2'));
    });
  });

  group('SaveManager.hasSave', () {
    test('false без сохранения', () async {
      expect(await SaveManager.hasSave(), false);
    });

    test('true после сохранения', () async {
      await SaveManager.save(makeSave());
      expect(await SaveManager.hasSave(), true);
    });
  });

  group('SaveManager.delete', () {
    test('удаляет сохранение', () async {
      await SaveManager.save(makeSave());
      final ok = await SaveManager.delete();
      expect(ok, true);
      expect(await SaveManager.hasSave(), false);
      expect(await SaveManager.load(), isNull);
    });
  });

  group('SaveManager.formatSaveDate', () {
    test('«только что» для свежего', () {
      final now = DateTime.now();
      final result = SaveManager.formatSaveDate(now);
      expect(result, 'только что');
    });

    test('«X мин назад» для 5 минут', () {
      final past = DateTime.now().subtract(const Duration(minutes: 5));
      final result = SaveManager.formatSaveDate(past);
      expect(result, contains('мин'));
    });

    test('«X ч назад» для 3 часов', () {
      final past = DateTime.now().subtract(const Duration(hours: 3));
      final result = SaveManager.formatSaveDate(past);
      expect(result, contains('ч'));
    });

    test('«X дн назад» для 3 дней', () {
      final past = DateTime.now().subtract(const Duration(days: 3));
      final result = SaveManager.formatSaveDate(past);
      expect(result, contains('дн'));
    });
  });
}