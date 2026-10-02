// tool/validate.dart
//
// Валидатор JSON-файлов проекта «Тёмные часы».
// Запуск: dart run tool/validate.dart
//
// Проверяет:
// - Синтаксис JSON
// - Уникальность id в сюжете
// - Все next/entry_nodes/end_nodes ведут к существующим нодам
// - Все ссылки на предметы (items) существуют
// - Все ссылки на локации (locations) существуют
// - Все ссылки на рецепты, условия, search_events существуют
// - Обязательные поля на месте
//
// Возвращает exit code 1, если есть ошибки (для CI).

import 'dart:convert';
import 'dart:io';

// ═══════════════════════════════════════════════════════════
// ГЛАВНАЯ ФУНКЦИЯ
// ═══════════════════════════════════════════════════════════

void main(List<String> args) {
  print('');
  print('🔍 Валидатор JSON — Тёмные часы');
  print('═' * 60);

  final validator = Validator();

  // ═══════════ 1. Загружаем справочники ═══════════
  print('');
  print('📚 Загрузка справочников...');
  print('─' * 60);

  validator.loadItemIds();
  validator.loadLocationIds();
  validator.loadConditionIds();

  print('  ✅ Предметов: ${validator.itemIds.length}');
  print('  ✅ Локаций: ${validator.locationIds.length}');
  print('  ✅ Состояний: ${validator.conditionIds.length}');

  // ═══════════ 2. Валидация сюжета ═══════════
  print('');
  print('📖 Сюжет');
  print('─' * 60);

  validator.validateAllStories();

  // ═══════════ 3. Валидация локаций ═══════════
  print('');
  print('🗺️  Локации');
  print('─' * 60);

  validator.validateLocations();

  // ═══════════ 4. Валидация рецептов ═══════════
  print('');
  print('🔨 Рецепты');
  print('─' * 60);

  validator.validateRecipes();

  // ═══════════ 5. Валидация условий ═══════════
  print('');
  print('🦠 Состояния');
  print('─' * 60);

  validator.validateConditions();

  // ═══════════ 6. Валидация search_events ═══════════
  print('');
  print('🎲 События поиска');
  print('─' * 60);

  validator.validateSearchEvents();

  // ═══════════ 7. Валидация достижений ═══════════
  print('');
  print('🏆 Достижения');
  print('─' * 60);

  validator.validateAchievements();

  // ═══════════ 8. Итог ═══════════
  print('');
  print('═' * 60);
  print('🎯 Итог');
  print('─' * 60);

  print('  📄 Файлов проверено: ${validator.filesChecked}');
  print('  ${validator.errorCount == 0 ? "✅" : "❌"} Ошибок: ${validator.errorCount}');
  print('  ${validator.warningCount == 0 ? "✅" : "⚠️ "} Предупреждений: ${validator.warningCount}');

  print('');
  if (validator.errorCount > 0) {
    print('❌ Валидация провалена. Исправь ошибки выше.');
    exit(1);
  } else {
    print('🎉 Валидация успешна! Все ссылки корректны.');
    exit(0);
  }
}

// ═══════════════════════════════════════════════════════════
// ВАЛИДАТОР
// ═══════════════════════════════════════════════════════════

class Validator {
  // Справочники
  final Set<String> itemIds = {};
  final Set<String> locationIds = {};
  final Set<String> conditionIds = {};

  // Счётчики
  int filesChecked = 0;
  int errorCount = 0;
  int warningCount = 0;

  // ═══════════ Загрузка справочников ═══════════

  /// Загружает все id предметов из weapons, tools, consumables, armor, resources
  void loadItemIds() {
    _loadIdsFromFile('assets/data/weapons.json', 'weapons', itemIds);
    _loadIdsFromFile('assets/data/tools.json', 'tools', itemIds);
    _loadIdsFromFile('assets/data/consumables.json', 'consumables', itemIds);
    _loadIdsFromFile('assets/data/armor.json', 'armor', itemIds);
    _loadIdsFromFile('assets/data/resources.json', 'resources', itemIds);

    // Дополнительные id предметов, которые крафтятся (molotov, torch, spear и т.п.)
    itemIds.addAll([
      'molotov',
      'torch',
      'spear',
      'fishing_rod',
      'trap_snare',
      'water_filter',
      'key',
      'note',
      'photo',
      'binoculars',
      'ammo_box',
      '9mm',
      '357',
      'shotgun_shell',
      '762',
      'pipe_bullet',
      'arrow',
      'bolt',
      'flare',
      'ammo',
      'lock_pick_crafted',
    ]);
  }

  /// Загружает id всех локаций
  void loadLocationIds() {
    _loadIdsFromFile('assets/data/locations.json', 'locations', locationIds);
  }

  /// Загружает id всех состояний
  void loadConditionIds() {
    _loadIdsFromFile('assets/data/conditions.json', 'conditions', conditionIds);
  }

  /// Универсальный загрузчик id из JSON-файла
  void _loadIdsFromFile(String path, String key, Set<String> target) {
    try {
      final file = File(path);
      if (!file.existsSync()) {
        _error('Файл не найден: $path');
        return;
      }
      final content = file.readAsStringSync();
      final json = jsonDecode(content) as Map<String, dynamic>;
      final list = json[key] as List?;
      if (list == null) {
        _error('Ключ "$key" не найден в $path');
        return;
      }
      for (final item in list) {
        final id = (item as Map)['id'] as String?;
        if (id != null) target.add(id);
      }
    } catch (e) {
      _error('Ошибка загрузки $path: $e');
    }
  }

  // ═══════════ Валидация сюжета ═══════════

  /// Проходит по всем персонажам и главам сюжета
  void validateAllStories() {
    const characters = ['boris', 'alina', 'ivan', 'andrey', 'darya'];

    for (final character in characters) {
      final storyDir = Directory('assets/data/story/$character/chapter_1');
      if (!storyDir.existsSync()) {
        _warn('Нет папки сюжета: assets/data/story/$character/chapter_1');
        continue;
      }

      _validateChapter(character, storyDir);
    }
  }

  /// Валидация одной главы одного персонажа
  void _validateChapter(String character, Directory dir) {
    // ═══════ 1. Загружаем meta.json ═══════
    final metaFile = File('${dir.path}/meta.json');
    if (!metaFile.existsSync()) {
      _error('Нет meta.json в ${dir.path}');
      return;
    }

    Map<String, dynamic> meta;
    try {
      meta = jsonDecode(metaFile.readAsStringSync()) as Map<String, dynamic>;
      filesChecked++;
    } catch (e) {
      _error('Ошибка парсинга ${metaFile.path}: $e');
      return;
    }

    final acts = (meta['acts'] as List? ?? []).cast<Map<String, dynamic>>();
    final startNode = meta['acts']?[0]?['start_node'] as String?;

    // ═══════ 2. Загружаем все акты ═══════
    final Map<String, Map<String, dynamic>> allNodes = {};
    final Map<String, String> nodeToFile = {}; // id → файл (для диагностики)

    for (final act in acts) {
      final fileName = act['file'] as String?;
      if (fileName == null) {
        _error('$character: акт без поля "file"');
        continue;
      }

      final actFile = File('${dir.path}/$fileName');
      if (!actFile.existsSync()) {
        _error('$character: файл акта не найден: $fileName');
        continue;
      }

      Map<String, dynamic> actJson;
      try {
        actJson = jsonDecode(actFile.readAsStringSync()) as Map<String, dynamic>;
        filesChecked++;
      } catch (e) {
        _error('Ошибка парсинга $fileName: $e');
        continue;
      }

      final nodes = (actJson['nodes'] as List? ?? []).cast<Map<String, dynamic>>();

      for (final node in nodes) {
        final id = node['id'] as String?;
        if (id == null) {
          _error('$character/$fileName: нода без поля "id"');
          continue;
        }
        if (allNodes.containsKey(id)) {
          _error(
            '$character/$fileName: дубликат id ноды "$id" '
            '(уже встречается в ${nodeToFile[id]})',
          );
          continue;
        }
        allNodes[id] = node;
        nodeToFile[id] = fileName;
      }
    }

    // ═══════ 3. Проверяем ссылки ═══════
    int errorBefore = errorCount;

    // 3.1 start_node
    if (startNode != null && !allNodes.containsKey(startNode)) {
      _error(
        '$character: start_node "$startNode" не найден среди нод',
      );
    }

    // 3.2 entry_nodes из актов
    for (final act in acts) {
      final entryNodes = (act['entry_nodes'] as List? ?? []).cast<String>();
      for (final entry in entryNodes) {
        if (!allNodes.containsKey(entry)) {
          _error(
            '$character/${act['file']}: entry_node "$entry" не найден',
          );
        }
      }
    }

    // 3.3 end_nodes из meta
    // (может быть в meta как end_nodes верхнего уровня или в acts)
    final endNodes = (meta['end_nodes'] as List? ?? []).cast<String>();
    for (final end in endNodes) {
      if (!allNodes.containsKey(end)) {
        _error('$character: end_node "$end" не найден');
      }
    }

    // 3.4 Все next в choices + combat_victory/defeat/flee
    for (final entry in allNodes.entries) {
      final id = entry.key;
      final node = entry.value;

      // Обязательные поля
      if (node['title'] == null) {
        _error('$character/$id: нет поля "title"');
      }
      if (node['text'] == null) {
        _error('$character/$id: нет поля "text"');
      }

      final choices = (node['choices'] as List? ?? []).cast<Map<String, dynamic>>();

      for (int i = 0; i < choices.length; i++) {
        final choice = choices[i];

        // next
        final next = choice['next'] as String?;
        if (next == null) {
          _error('$character/$id: choice[$i] без поля "next"');
        } else if (!allNodes.containsKey(next)) {
          _error(
            '$character/$id: choice[$i].next = "$next" → нода не найдена',
          );
        }

        // combat_*
        final effects = choice['effects'] as Map<String, dynamic>?;
        if (effects != null) {
          for (final key in ['combat_victory', 'combat_defeat', 'combat_flee']) {
            final target = effects[key] as String?;
            if (target != null && !allNodes.containsKey(target)) {
              _error(
                '$character/$id: choice[$i].effects.$key = '
                '"$target" → нода не найдена',
              );
            }
          }

          // inventory_add — проверяем, что предметы существуют
          final addIds = effects['inventory_add'] as List?;
          if (addIds != null) {
            for (final itemId in addIds.cast<String>()) {
              if (!itemIds.contains(itemId)) {
                _warn(
                  '$character/$id: choice[$i].effects.inventory_add '
                  '"$itemId" → предмет не найден в справочнике',
                );
              }
            }
          }

          final removeIds = effects['inventory_remove'] as List?;
          if (removeIds != null) {
            for (final itemId in removeIds.cast<String>()) {
              if (!itemIds.contains(itemId)) {
                _warn(
                  '$character/$id: choice[$i].effects.inventory_remove '
                  '"$itemId" → предмет не найден',
                );
              }
            }
          }
        }

        // requires
        final requires = choice['requires'] as Map<String, dynamic>?;
        if (requires != null) {
          final hasItem = requires['has_item'] as String?;
          if (hasItem != null && !itemIds.contains(hasItem)) {
            _error(
              '$character/$id: choice[$i].requires.has_item = '
              '"$hasItem" → предмет не найден',
            );
          }
          final notItem = requires['not_item'] as String?;
          if (notItem != null && !itemIds.contains(notItem)) {
            _warn(
              '$character/$id: choice[$i].requires.not_item = '
              '"$notItem" → предмет не найден',
            );
          }
        }
      }

      // Проверка: если нода не END_ и не act_X_end, но без choices — это ошибка
      if (choices.isEmpty) {
        final isEnd = id.startsWith('END_');
        final isActEnd = id.endsWith('_end');
        if (!isEnd && !isActEnd) {
          _warn(
            '$character/$id: нет choices, но id не END_* и не *_end',
          );
        }
      }
    }

    // ═══════ 4. Вывод ═══════
    final chapterErrors = errorCount - errorBefore;
    if (chapterErrors == 0) {
      print(
        '  ✅ $character/chapter_1 — ${allNodes.length} нод, '
        '${acts.length} актов',
      );
    } else {
      print(
        '  ❌ $character/chapter_1 — $chapterErrors ошибок '
        '(нод: ${allNodes.length})',
      );
    }
  }

  // ═══════════ Валидация локаций ═══════════

  void validateLocations() {
    final file = File('assets/data/locations.json');
    if (!file.existsSync()) {
      _error('locations.json не найден');
      return;
    }

    Map<String, dynamic> json;
    try {
      json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      filesChecked++;
    } catch (e) {
      _error('Ошибка парсинга locations.json: $e');
      return;
    }

    final locations = (json['locations'] as List).cast<Map<String, dynamic>>();
    int errors = 0;

    for (final loc in locations) {
      final id = loc['id'] as String? ?? '<без id>';
      int locErrors = 0;

      // connections
      final connections = (loc['connections'] as List? ?? []).cast<String>();
      for (final target in connections) {
        if (!locationIds.contains(target)) {
          _error('Локация "$id": connections → "$target" не найдена');
          locErrors++;
        }
      }

      // loot_pool
      final lootPool = (loc['loot_pool'] as List? ?? []).cast<String>();
      for (final item in lootPool) {
        if (!itemIds.contains(item)) {
          _warn('Локация "$id": loot_pool → "$item" не найден');
        }
      }

      // unlocked_by
      final unlockedBy = loc['unlocked_by'] as String?;
      if (unlockedBy != null && !locationIds.contains(unlockedBy)) {
        _error('Локация "$id": unlocked_by → "$unlockedBy" не найдена');
        locErrors++;
      }

      // search_events
      final events = (loc['search_events'] as List? ?? []).cast<Map<String, dynamic>>();
      for (int i = 0; i < events.length; i++) {
        final effect = events[i]['effect'] as Map<String, dynamic>?;
        if (effect == null) continue;

        final unlock = effect['unlock_location'] as String?;
        if (unlock != null && unlock != 'auto' && !locationIds.contains(unlock)) {
          _error(
            'Локация "$id": search_events[$i].unlock_location = '
            '"$unlock" не найдена',
          );
          locErrors++;
        }

        final loot = (effect['random_loot'] as List? ?? []).cast<String>();
        for (final item in loot) {
          if (!itemIds.contains(item)) {
            _warn(
              'Локация "$id": search_events[$i].random_loot → '
              '"$item" не найден',
            );
          }
        }
      }

      if (locErrors > 0) errors += locErrors;
    }

    if (errors == 0) {
      print('  ✅ ${locations.length} локаций, все ссылки валидны');
    } else {
      print('  ❌ ${locations.length} локаций, $errors ошибок');
    }
  }

  // ═══════════ Валидация рецептов ═══════════

  void validateRecipes() {
    final file = File('assets/data/recipes.json');
    if (!file.existsSync()) {
      _error('recipes.json не найден');
      return;
    }

    Map<String, dynamic> json;
    try {
      json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      filesChecked++;
    } catch (e) {
      _error('Ошибка парсинга recipes.json: $e');
      return;
    }

    final recipes = (json['recipes'] as List).cast<Map<String, dynamic>>();
    int errors = 0;

    for (final recipe in recipes) {
      final id = recipe['id'] as String? ?? '<без id>';
      final resultId = recipe['result_id'] as String?;

      // result_id не обязателен быть в справочнике (может крафтиться)
      // но предупредим, если неизвестен
      if (resultId != null && !itemIds.contains(resultId)) {
        _warn('Рецепт "$id": result_id "$resultId" не в справочнике');
      }

      // ingredients
      final ingredients =
          (recipe['ingredients'] as List? ?? []).cast<Map<String, dynamic>>();
      for (int i = 0; i < ingredients.length; i++) {
        final ingId = ingredients[i]['id'] as String?;
        if (ingId == null) {
          _error('Рецепт "$id": ingredients[$i] без id');
          errors++;
        } else if (!itemIds.contains(ingId)) {
          _error('Рецепт "$id": ingredients[$i].id = "$ingId" не найден');
          errors++;
        }
      }
    }

    if (errors == 0) {
      print('  ✅ ${recipes.length} рецептов, все ссылки валидны');
    } else {
      print('  ❌ ${recipes.length} рецептов, $errors ошибок');
    }
  }

  // ═══════════ Валидация условий ═══════════

  void validateConditions() {
    final file = File('assets/data/conditions.json');
    if (!file.existsSync()) {
      _error('conditions.json не найден');
      return;
    }

    Map<String, dynamic> json;
    try {
      json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      filesChecked++;
    } catch (e) {
      _error('Ошибка парсинга conditions.json: $e');
      return;
    }

    final conditions = (json['conditions'] as List).cast<Map<String, dynamic>>();
    int errors = 0;

    for (final cond in conditions) {
      final id = cond['id'] as String? ?? '<без id>';
      final cureItems = (cond['cure_items'] as List? ?? []).cast<String>();

      for (final item in cureItems) {
        if (!itemIds.contains(item)) {
          _warn('Состояние "$id": cure_items → "$item" не найден');
        }
      }
    }

    if (errors == 0) {
      print('  ✅ ${conditions.length} состояний, все ссылки валидны');
    } else {
      print('  ❌ ${conditions.length} состояний, $errors ошибок');
    }
  }

  // ═══════════ Валидация search_events ═══════════

  void validateSearchEvents() {
    final file = File('assets/data/search_events.json');
    if (!file.existsSync()) {
      _error('search_events.json не найден');
      return;
    }

    Map<String, dynamic> json;
    try {
      json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      filesChecked++;
    } catch (e) {
      _error('Ошибка парсинга search_events.json: $e');
      return;
    }

    final events = (json['events'] as List).cast<Map<String, dynamic>>();
    int errors = 0;

    for (final event in events) {
      final id = event['id'] as String? ?? '<без id>';
      final chance = event['chance'];
      if (chance == null) {
        _error('Событие "$id": нет chance');
        errors++;
      } else if ((chance as num) < 0 || chance > 1) {
        _error('Событие "$id": chance=$chance вне диапазона [0,1]');
        errors++;
      }

      final effect = event['effect'] as Map<String, dynamic>?;
      if (effect == null) continue;

      final unlock = effect['unlock_location'] as String?;
      if (unlock != null && unlock != 'auto' && !locationIds.contains(unlock)) {
        _error('Событие "$id": unlock_location "$unlock" не найдена');
        errors++;
      }

      final loot = (effect['random_loot'] as List? ?? []).cast<String>();
      for (final item in loot) {
        if (!itemIds.contains(item)) {
          _warn('Событие "$id": random_loot → "$item" не найден');
        }
      }
    }

    if (errors == 0) {
      print('  ✅ ${events.length} событий, все ссылки валидны');
    } else {
      print('  ❌ ${events.length} событий, $errors ошибок');
    }
  }

  // ═══════════ Валидация достижений ═══════════

  void validateAchievements() {
    final file = File('assets/data/achievements.json');
    if (!file.existsSync()) {
      _error('achievements.json не найден');
      return;
    }

    Map<String, dynamic> json;
    try {
      json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      filesChecked++;
    } catch (e) {
      _error('Ошибка парсинга achievements.json: $e');
      return;
    }

    const validCategories = {
      'combat', 'survival', 'story', 'crafting', 'loot', 'medicine',
    };

    final achievements =
        (json['achievements'] as List).cast<Map<String, dynamic>>();
    int errors = 0;
    final ids = <String>{};

    for (final ach in achievements) {
      final id = ach['id'] as String? ?? '<без id>';
      if (ids.contains(id)) {
        _error('Достижение "$id": дубликат id');
        errors++;
      }
      ids.add(id);

      final category = ach['category'] as String?;
      if (category != null && !validCategories.contains(category)) {
        _warn(
          'Достижение "$id": неизвестная категория "$category" '
          '(допустимые: ${validCategories.join(", ")})',
        );
      }
    }

    if (errors == 0) {
      print('  ✅ ${achievements.length} достижений, все валидны');
    } else {
      print('  ❌ ${achievements.length} достижений, $errors ошибок');
    }
  }

  // ═══════════ Утилиты ═══════════

  void _error(String message) {
    print('  ❌ $message');
    errorCount++;
  }

  void _warn(String message) {
    print('  ⚠️  $message');
    warningCount++;
  }
}